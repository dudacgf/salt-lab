#!/usr/bin/env python3

"""
``check_system`` is a `Nagios <https://www.nagios.org>`_ / `Icinga
<https://icinga.com>`_ monitoring plugin to check systemd. This Python script
will report a degraded system to your monitoring solution. It can also be used
to monitor individual systemd services (with the ``-u, --unit`` parameter) and
timers units (with the ``-t, --dead-timers`` parameter).

To learn more about the project, please visit the repository on `Github
<https://github.com/Josef-Friedrich/check_systemd>`_.

Monitoring scopes
=================

* State of unites (``context=units``)
* Timers (``context=timers``)
* Startup time (``context=startup_time``)

Data sources
============

* D-Bus (``dbus``)
* Command line interface (``cli``)

This plugin is based on a Python package named `nagiosplugin
<https://pypi.org/project/nagiosplugin/>`_. ``nagiosplugin`` has a fine-grained
class model to separate concerns. A Nagios / Icinga plugin must perform these
three steps: data `acquisition`, `evaluation` and `presentation`.
``nagiosplugin`` provides for this three steps three classes: ``Resource``,
``Context``, ``Summary``. ``check_systemd`` extends this three model classes in
the following subclasses:

Acquisition (``Resource``)
==========================

* :class:`UnitsResource` (``context=units``)
* :class:`TimersResource` (``context=timers``)
* :class:`StartupTimeResource` (``context=startup_time``)
* :class:`PerformanceDataResource` (``context=performance_data``)

Evaluation (``Context``)
========================

* :class:`UnitsContext` (``context=units``)
* :class:`TimersContext` (``context=timers``)
* :class:`StartupTimeContext` (``context=timers``)
* :class:`PerformanceDataContext` (``context=performance_data``)

Presentation (``Summary``)
==========================

* :class:`SystemdSummary`
"""
import argparse
import collections.abc
import re
import subprocess
import typing

import nagiosplugin
from nagiosplugin import Metric, Result

__version__ = '2.3.1'


is_gi = True
"""true if the packages PyGObject (gi) or Pure Python GObject Introspection
Bindings (pgi) are available."""

try:
    # Look for gi https://pygobject.readthedocs.io/en/latest/index.html
    from gi.repository.Gio import BusType, DBusProxy
except ImportError:
    try:
        # Fallback to pgi Pure Python GObject Introspection Bindings
        # https://github.com/pygobject/pgi
        from pgi.repository.Gio import BusType, DBusProxy
    except ImportError:
        # Fallback to the command line interface source.
        is_gi = False


class OptionContainer:
    """This class has the same attributes as the ``Namespace`` instance
    returned by the ``argparse`` package."""

    def __init__(self):
        self.include = []
        self.exclude = []
        self.unit = None
        self.data_source: str = None


opts = OptionContainer()
"""
We make is variable global to be able to access the command line arguments
everywhere in the plugin. In this variable the result of `parse_args()
<https://docs.python.org/3/library/argparse.html#argparse.ArgumentParser.parse_args>`_
is stored. It is an instance of the
`argparse.Namespace
<https://docs.python.org/3/library/argparse.html#argparse.Namespace>`_ class.
This variable is initialized in the main function. The variable is
intentionally not named ``args`` to avoid confusion with ``*args`` (Non-Keyword
Arguments).
"""


# Data source: D-Bus ##########################################################


class DbusManager:
    """
    This class holds the main entry point object of the D-Bus systemd API. See
    the section `The Manager Object
    <https://www.freedesktop.org/software/systemd/man/org.freedesktop.systemd1.html#The%20Manager%20Object>`_
    in the systemd D-Bus API.
    """

    def __init__(self):
        self.__manager = DBusProxy.new_for_bus_sync(
            BusType.SYSTEM, 0, None, 'org.freedesktop.systemd1',
            '/org/freedesktop/systemd1', 'org.freedesktop.systemd1.Manager',
            None)

    @property
    def manager(self):
        return self.__manager


dbus_manager = None
"""
The systemd D-Bus API main entry point object, the so called “manager”.
"""
if is_gi:
    dbus_manager = DbusManager()


# Data source: CLI (command line interface) ###################################


def format_timespan_to_seconds(fmt_timespan: str) -> float:
    """Convert a timespan format string into secondes. Take a look at the
    systemd `time-util.c
    <https://github.com/systemd/systemd/blob/master/src/basic/time-util.c>`_
    source code.

    :param fmt_timespan: for example ``2.345s`` or ``3min 45.234s`` or
      ``34min left`` or ``2 months 8 days``

    :return: The seconds
    """
    for replacement in [
        ['years', 'y'],
        ['months', 'month'],
        ['weeks', 'w'],
        ['days', 'd'],
    ]:
        fmt_timespan = fmt_timespan.replace(
            ' ' + replacement[0], replacement[1]
        )
    seconds = {
        'y': 31536000,  # 365 * 24 * 60 * 60
        'month': 2592000,  # 30 * 24 * 60 * 60
        'w': 604800,  # 7 * 24 * 60 * 60
        'd': 86400,  # 24 * 60 * 60
        'h': 3600,  # 60 * 60
        'min': 60,
        's': 1,
        'ms': 0.001,
    }
    result = 0
    for span in fmt_timespan.split():
        match = re.search(r'([\d\.]+)([a-z]+)', span)
        if match:
            value = match.group(1)
            unit = match.group(2)
            result += float(value) * seconds[unit]
    return round(float(result), 3)


def execute_cli(args: typing.Union[str, typing.Iterator[str]]) -> str:
    """Execute a command on the command line (cli = command line interface))
    and capture the stdout. This is a wrapper around ``subprocess.Popen``.

    :param args: A list of programm arguments.

    :raises nagiosplugin.CheckError: If the command produces some stderr output
      or if an OSError exception occurs.

    :return: The stdout of the command.
    """
    try:
        p = subprocess.Popen(args,
                             stderr=subprocess.PIPE,
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE)
        stdout, stderr = p.communicate()
    except OSError as e:
        raise nagiosplugin.CheckError(e)

    if p.returncode != 0:
        raise nagiosplugin.CheckError('The command exits with a none-zero'
                                      'return code ({})'.format(p.returncode))

    if stderr:
        raise nagiosplugin.CheckError(stderr)

    if stdout:
        stdout = stdout.decode('utf-8')
        return stdout


class TableParser:
    """This class reads the text tables that some systemd commands like
    ``systemctl list-units`` or ``systemctl list-timers`` produce."""

    def __init__(self, stdout):
        rows = stdout.splitlines()
        self.header_row = TableParser.__normalize_header(rows[0])
        self.column_lengths = TableParser.__detect_lengths(self.header_row)
        self.columns = TableParser.__split_row(
            self.header_row, self.column_lengths)
        counter = 0
        for line in rows:
            # The table footer is separted by a blank line
            if line == '':
                break
            counter += 1
        self.body_rows = rows[1:counter]

    @staticmethod
    def __normalize_header(header_row: str) -> str:
        """Replace a single space character that is surrounded by word
        characters with an underscore and convert the word to lower case. Now
        we can more easily detect the column boundaries. A column starts with a
        word followed by whitespaces. The first word character after a
        whitespace marks the beginning of a new row."""
        header_row = header_row.lower()
        header_row = re.sub(r'(\w) (\w)', r'\1_\2', header_row)
        return header_row

    @staticmethod
    def __detect_lengths(header_row: str) -> list:
        column_lengths = []
        match = re.search(r'^ +', header_row)
        if match:
            whitespace_prefix_length = match.end()
            column_lengths.append(whitespace_prefix_length)
            header_row = header_row[whitespace_prefix_length:]

        header_row = re.sub(r'(\w) (\w)', '\1_\2', header_row)
        word = 0
        space = 0

        for char in header_row:
            if word and space > 1 and char != ' ':
                column_lengths.append(word + space)
                word = 0
                space = 0

            if char == ' ':
                space += 1
            else:
                word += 1

        return column_lengths

    @staticmethod
    def __split_row(line: str, column_lengths: list) -> list:
        columns = []
        right = 0
        for length in column_lengths:
            left = right
            right = right + length
            columns.append(line[left:right].strip())
        columns.append(line[right:].strip())
        return columns

    @property
    def row_count(self):
        """The number of rows. Only the body rows are counted. The header row
        is not taken into account."""
        return len(self.body_rows)

    def check_header(self, column_names: typing.Iterable):
        """Check if the specified column names are present in the header row of
        the text table. Raise an exception if not."""
        for column_name in column_names:
            if self.header_row.find(column_name) == -1:
                msg = 'The column heading \'{}\' couldn’t found in the ' \
                      'table header. Possibly the table layout of systemctl ' \
                      'has changed.'
                raise ValueError(msg.format(column_name))

    def get_row(self, row_number: int) -> dict:
        """Retrieve a table row as a dictionary. The keys are taken from the
        header row. The first row number is 0.

        :param row_number: The index number of the table row starting at 0.

        """
        body_columns = TableParser.__split_row(self.body_rows[row_number],
                                               self.column_lengths)

        result = {}

        index = 0
        for column in self.columns:
            if column == '':
                key = 'column_{}'.format(index)
            else:
                key = column
            result[key] = body_columns[index]
            index += 1
        return result

    def list_rows(self) -> typing.Generator[dict, None, None]:
        """List all rows."""
        for i in range(0, self.row_count):
            yield self.get_row(i)


# Unit abstraction ############################################################


def match_multiple(unit_name: str,
                   regexes: typing.Union[str, typing.Iterator[str]]) -> bool:
    """
    Match multiple regular expressions against a unit name.

    :param unit_name: The unit name to be matched.

    :param regexes: A single regular expression (``include='.*service'``) or a
      list of regular expressions (``include=('.*service', '.*mount')``).

    :return: True if one regular expression matches"""
    if isinstance(regexes, str):
        regexes = [regexes]
    for regex in regexes:
        if re.match(regex, unit_name):
            return True
    return False


class Unit:
    """This class bundles all state related informations of a systemd unit in a
    object. This class is inherited by the class ``DbusUnit`` and the
    attributes are overwritten by properties.
    """

    def __init__(self, **kwargs):
        self.name = kwargs.get('name')
        """The name of the system unit, for example ``nginx.service``. In the
        command line table of the command ``systemctl list-units`` is the
        column containing unit names titled with “UNIT”.
        """

        self.active_state = kwargs.get('active_state')
        """From the `D-Bus interface of systemd documentation
        <https://www.freedesktop.org/software/systemd/man/org.freedesktop.systemd1.html#Properties1>`_:

        ``ActiveState`` contains a state value that reflects whether the unit
        is currently active or not. The following states are currently defined:

        * ``active``,
        * ``reloading``,
        * ``inactive``,
        * ``failed``,
        * ``activating``, and
        * ``deactivating``.

        ``active`` indicates that unit is active (obviously...).

        ``reloading`` indicates that the unit is active and currently reloading
        its configuration.

        ``inactive`` indicates that it is inactive and the previous run was
        successful or no previous run has taken place yet.

        ``failed`` indicates that it is inactive and the previous run was not
        successful (more information about the reason for this is available on
        the unit type specific interfaces, for example for services in the
        Result property, see below).

        ``activating`` indicates that the unit has previously been inactive but
        is currently in the process of entering an active state.

        Conversely ``deactivating`` indicates that the unit is currently in the
        process of deactivation.
        """

        self.sub_state = kwargs.get('sub_state')
        """From the `D-Bus interface of systemd documentation
        <https://www.freedesktop.org/software/systemd/man/org.freedesktop.systemd1.html#Properties1>`_:

        ``SubState`` encodes states of the same state machine that
        ``ActiveState`` covers, but knows more fine-grained states that are
        unit-type-specific. Where ``ActiveState`` only covers six high-level
        states, ``SubState`` covers possibly many more low-level
        unit-type-specific states that are mapped to the six high-level states.
        Note that multiple low-level states might map to the same high-level
        state, but not vice versa. Not all high-level states have low-level
        counterparts on all unit types.

        All sub states are listed in the file `basic/unit-def.c
        <https://github.com/systemd/systemd/blob/main/src/basic/unit-def.c>`_
        of the systemd source code:

        * automount: ``dead``, ``waiting``, ``running``, ``failed``
        * device: ``dead``, ``tentative``, ``plugged``
        * mount: ``dead``, ``mounting``, ``mounting-done``, ``mounted``,
          ``remounting``, ``unmounting``, ``remounting-sigterm``,
          ``remounting-sigkill``, ``unmounting-sigterm``,
          ``unmounting-sigkill``, ``failed``, ``cleaning``
        * path: ``dead``, ``waiting``, ``running``, ``failed``
        * scope: ``dead``, ``running``, ``abandoned``, ``stop-sigterm``,
          ``stop-sigkill``, ``failed``
        * service: ``dead``, ``condition``, ``start-pre``, ``start``,
          ``start-post``, ``running``, ``exited``, ``reload``, ``stop``,
          ``stop-watchdog``, ``stop-sigterm``, ``stop-sigkill``, ``stop-post``,
          ``final-watchdog``, ``final-sigterm``, ``final-sigkill``, ``failed``,
          ``auto-restart``, ``cleaning``
        * slice: ``dead``, ``active``
        * socket: ``dead``, ``start-pre``, ``start-chown``, ``start-post``,
          ``listening``, ``running``, ``stop-pre``, ``stop-pre-sigterm``,
          ``stop-pre-sigkill``, ``stop-post``, ``final-sigterm``,
          ``final-sigkill``, ``failed``, ``cleaning``
        * swap: ``dead``, ``activating``, ``activating-done``, ``active``,
          ``deactivating``, ``deactivating-sigterm``, ``deactivating-sigkill``,
          ``failed``, ``cleaning``
        * target:``dead``, ``active``
        * timer: ``dead``, ``waiting``, ``running``, ``elapsed``, ``failed``
        """

        self.load_state = kwargs.get('load_state')
        """From the `D-Bus interface of systemd documentation
        <https://www.freedesktop.org/software/systemd/man/org.freedesktop.systemd1.html#Properties1>`_:

        ``LoadState`` contains a state value that reflects whether the
        configuration file of this unit has been loaded. The following states
        are currently defined:

        * ``loaded``,
        * ``error`` and
        * ``masked``.

        ``loaded`` indicates that the configuration was successfully loaded.

        ``error`` indicates that the configuration failed to load, the
        ``LoadError`` field contains information about the cause of this
        failure.

        ``masked`` indicates that the unit is currently masked out (i.e.
        symlinked to /dev/null or suchlike).

        Note that the ``LoadState`` is fully orthogonal to the ``ActiveState``
        (see below) as units without valid loaded configuration might be active
        (because configuration might have been reloaded at a time where a unit
        was already active).
        """

    def convert_to_exitcode(self):
        """Convert the different systemd states into a Nagios compatible
        exit code.

        :return: A Nagios compatible exit code: 0, 1, 2, 3
        :rtype: int"""
        if self.load_state == 'error' or self.active_state == 'failed':
            return nagiosplugin.Critical
        return nagiosplugin.Ok


class SystemdUnitTypesList(collections.abc.MutableSequence):

    def __init__(self, *args):
        self.unit_types = list()
        self.__all_types = (
            'service', 'socket', 'target', 'device', 'mount', 'automount',
            'timer', 'swap', 'path', 'slice', 'scope'
        )
        self.extend(list(args))

    def __len__(self):
        return len(self.unit_types)

    def __getitem__(self, index):
        return self.unit_types[index]

    def __delitem__(self, index):
        del self.unit_types[index]

    def __setitem__(self, index, unit_type):
        self.__check_type(unit_type)
        self.unit_types[index] = unit_type

    def __str__(self):
        return str(self.unit_types)

    def insert(self, index, unit_type):
        self.__check_type(unit_type)
        self.unit_types.insert(index, unit_type)

    def __check_type(self, type):
        if type not in self.__all_types:
            raise ValueError('The given type \'{}\' is not a valid systemd '
                             'unit type.'.format(type))

    def convert_to_regexp(self):
        return r'.*\.({})$'.format('|'.join(self.unit_types))


class UnitNameFilter:
    """This class stores all system unit names (e. g. ``nginx.service`` or
    ``fstrim.timer``) and provides a interface to filter the names by regular
    expressions."""

    def __init__(self, unit_names=()):
        self.__unit_names = set(unit_names)

    def add(self, unit_name: str):
        """Add one unit name.

        :param unit_name: The name of the unit, for example ``apt.timer``.
        """
        self.__unit_names.add(unit_name)

    def get(self) -> typing.Set[str]:
        """Get all stored unit names."""
        return self.__unit_names

    def list(self,
             include: typing.Union[str, typing.Iterator[str]] = None,
             exclude: typing.Union[str, typing.Iterator[str]] = None
             ) -> typing.Generator[str, None, None]:
        """
        List all unit names or apply filters (``include`` or ``exclude``) to
        the list of unit names.

        :param include: If the unit name matches the provided regular
          expression, it is included in the list of unit names. A single
          regular expression (``include='.*service'``) or a list of regular
          expressions (``include=('.*service', '.*mount')``).

        :param exclude: If the unit name matches the provided regular
          expression, it is excluded from the list of unit names. A single
          regular expression (``exclude='.*service'``) or a list of regular
          expressions (``exclude=('.*service', '.*mount')``).
        """
        for name in self.__unit_names:

            if include and not match_multiple(name, include):
                name = None

            if name and exclude and match_multiple(name, exclude):
                name = None

            if name:
                yield name


class UnitCache:
    """This class is a container class for systemd units."""

    def __init__(self):
        self.__units = {}
        self.__name_filter = UnitNameFilter()

    def __add_unit(self, unit: Unit):
        self.__units[unit.name] = unit
        self.__name_filter.add(unit.name)

    def add_unit(self, unit: Unit = None, name: str = None,
                 active_state: str = None, sub_state: str = None,
                 load_state: str = None) -> Unit:
        if not unit:
            unit = Unit()
        if name:
            unit.name = name
        if active_state:
            unit.active_state = active_state
        if sub_state:
            unit.sub_state = sub_state
        if load_state:
            unit.load_state = load_state
        self.__add_unit(unit)
        return unit

    def get(self, name=None):
        if name:
            return self.__units[name]

    def list(self,
             include: typing.Union[str, typing.Iterator[str]] = None,
             exclude: typing.Union[str, typing.Iterator[str]] = None
             ) -> typing.Generator[Unit, None, None]:
        """
        List all units or apply filters (``include`` or ``exclude``) to
        the list of unit.

        :param include: If the unit name matches the provided regular
          expression, it is included in the list of unit names. A single
          regular expression (``include='.*service'``) or a list of regular
          expressions (``include=('.*service', '.*mount')``).

        :param exclude: If the unit name matches the provided regular
          expression, it is excluded from the list of unit names. A single
          regular expression (``exclude='.*service'``) or a list of regular
          expressions (``exclude=('.*service', '.*mount')``).
        """
        for name in self.__name_filter.list(include=include, exclude=exclude):
            yield self.__units[name]

    @property
    def count(self):
        return len(self.__units)

    def count_by_states(self, states: typing.Iterator[str],
                        include: typing.Union[str, typing.Iterator[str]] =
                        None, exclude: typing.Union[str, typing.Iterator[str]]
                        = None) -> dict:
        states_normalized = []
        counter = {}
        for state_spec in states:
            # state_proerty:state_value
            # for example: active_state:failed
            state_property = state_spec.split(':')[0]
            state_value = state_spec.split(':')[1]
            state = {
                'property': state_property,
                'value': state_value,
                'spec': state_spec,
            }
            states_normalized.append(state)
            counter[state_spec] = 0

        for unit in self.list(include=include, exclude=exclude):
            for state in states_normalized:
                if getattr(unit, state['property']) == state['value']:
                    counter[state['spec']] += 1

        return counter


class CliUnitCache(UnitCache):

    def __init__(self):
        super().__init__()
        stdout = execute_cli(['systemctl', 'list-units', '--all'])
        if stdout:
            table_parser = TableParser(stdout)
            table_parser.check_header(('unit', 'active', 'sub', 'load'))
            for row in table_parser.list_rows():
                self.add_unit(name=row['unit'], active_state=row['active'],
                              sub_state=row['sub'], load_state=row['load'])


class DbusUnitCache(UnitCache):

    def __init__(self):
        super().__init__()
        all_units = dbus_manager.manager.ListUnits()
        for (name, _, load_state, active_state, sub_state,
             _, _, _, _, _) in all_units:
            self.add_unit(name=name, active_state=active_state,
                          sub_state=sub_state, load_state=load_state)


unit_cache: UnitCache = None
"""An instance of :class:`DbusUnitCache` or :class:`CliUnitCache`"""


# Acquisition: *Resource ######################################################


class UnitsResource(nagiosplugin.Resource):

    name = 'SYSTEMD'

    def probe(self) -> typing.Generator[Metric, None, None]:
        counter = 0
        for unit in unit_cache.list(include=opts.include,
                                    exclude=opts.exclude):
            yield Metric(name=unit.name, value=unit, context='units')
            counter += 1

        if counter == 0:
            raise ValueError(
                'Please verify your --include-* and --exclude-* '
                'options. No units have been added for '
                'testing.'
            )


class TimersResource(nagiosplugin.Resource):
    """
    Resource that calls ``systemctl list-timers --all`` on the command line to
    get informations about dead / inactive timers. There is one type of systemd
    “degradation” which is normally not detected: dead / inactive timers.

    :param list excludes: A list of systemd unit names to exclude from the
      checks.
    """

    def __init__(self):
        super().__init__()

    name = 'SYSTEMD'

    def probe(self) -> typing.Generator[Metric, None, None]:
        """
        :return: generator that emits
          :class:`~nagiosplugin.metric.Metric` objects
        """
        stdout = execute_cli(['systemctl', 'list-timers', '--all'])

        # NEXT                          LEFT
        # Sat 2020-05-16 15:11:15 CEST  34min left

        # LAST                          PASSED
        # Sat 2020-05-16 14:31:56 CEST  4min 20s ago

        # UNIT             ACTIVATES
        # apt-daily.timer  apt-daily.service
        if stdout:
            table_parser = TableParser(stdout)
            state = nagiosplugin.Ok

            for row in table_parser.list_rows():
                unit = row['unit']
                if match_multiple(unit, opts.exclude):
                    continue
                next_date_time = row['next']

                if next_date_time == 'n/a':
                    passed_text = row['passed']

                    if passed_text == 'n/a':
                        state = nagiosplugin.Critical
                    else:
                        passed = format_timespan_to_seconds(
                            passed_text
                        )

                        if passed_text == 'n/a' or \
                                passed >= opts.timers_critical:
                            state = nagiosplugin.Critical
                        elif passed >= opts.timers_warning:
                            state = nagiosplugin.Warn

                yield Metric(
                    name=unit,
                    value=state,
                    context='timers'
                )


class StartupTimeResource(nagiosplugin.Resource):
    """Resource that calls ``systemd-analyze`` on the command line to get
    informations about the startup time."""

    name = 'SYSTEMD'

    def probe(self) -> typing.Generator[Metric, None, None]:
        """Query system state and return metrics.

        :return: generator that emits
          :class:`~nagiosplugin.metric.Metric` objects
        """
        stdout = None
        try:
            stdout = execute_cli(['systemd-analyze'])
        except nagiosplugin.CheckError:
            pass

        if stdout:
            # First line:
            # Startup finished in 1.672s (kernel) + 21.378s (userspace) =
            # 23.050s

            # On raspian no second line
            # Second line:
            # graphical.target reached after 1min 2.154s in userspace
            match = re.search(r'reached after (.+) in userspace', stdout)

            if not match:
                match = re.search(r' = (.+)\n', stdout)

            # Output when boot process is not finished:
            # Bootup is not yet finished. Please try again later.
            if match:
                yield Metric(name='startup_time',
                             value=format_timespan_to_seconds(match.group(1)),
                             context='startup_time')


class PerformanceDataResource(nagiosplugin.Resource):

    name = 'SYSTEMD'

    def probe(self) -> typing.Generator[Metric, None, None]:
        for state_spec, count in unit_cache.count_by_states((
                'active_state:failed',
                'active_state:active',
                'active_state:activating',
                'active_state:inactive',), exclude=opts.exclude).items():
            yield Metric(name='units_{}'.format(state_spec.split(':')[1]),
                         value=count,
                         context='performance_data')

        yield Metric(name='count_units', value=unit_cache.count,
                     context='performance_data')


class PerformanceDataDataSourceResource(nagiosplugin.Resource):

    name = 'SYSTEMD'

    def probe(self) -> typing.Generator[Metric, None, None]:

        yield Metric(name='data_source', value=opts.data_source,
                     context='performance_data')


# Evaluation: *Context ########################################################


class UnitsContext(nagiosplugin.Context):

    def __init__(self):
        super(UnitsContext, self).__init__('units')

    def evaluate(self, metric, resource) -> Result:
        """Determines state of a given metric.

        :param metric: associated metric that is to be evaluated
        :param resource: resource that produced the associated metric
            (may optionally be consulted)

        :returns: :class:`~.result.Result`
        """
        if isinstance(metric.value, Unit):
            unit = metric.value
            exitcode = unit.convert_to_exitcode()
            if exitcode != 0:
                hint = '{}: {}'.format(metric.name, unit.active_state)
                return self.result_cls(exitcode, metric=metric, hint=hint)

        if metric.value:
            hint = '{}: {}'.format(metric.name, metric.value)
        else:
            hint = metric.name

        # The option -u is not specifed
        if not metric.value:
            return self.result_cls(nagiosplugin.Ok, metric=metric, hint=hint)

        if opts.ignore_inactive_state and metric.value == 'failed':
            return self.result_cls(nagiosplugin.Critical, metric=metric,
                                   hint=hint)
        elif not opts.ignore_inactive_state and metric.value != 'active':
            return self.result_cls(nagiosplugin.Critical, metric=metric,
                                   hint=hint)
        else:
            return self.result_cls(nagiosplugin.Ok, metric=metric, hint=hint)


class TimersContext(nagiosplugin.Context):

    def __init__(self):
        super(TimersContext, self).__init__('timers')

    def evaluate(self, metric, resource):
        """Determines state of a given metric.

        :param metric: associated metric that is to be evaluated
        :param resource: resource that produced the associated metric
            (may optionally be consulted)

        :returns: :class:`~.result.Result`
        """
        return self.result_cls(metric.value, metric=metric, hint=metric.name)


class StartupTimeContext(nagiosplugin.ScalarContext):

    def __init__(self):
        super(StartupTimeContext, self).__init__('startup_time')
        if opts.scope_startup_time:
            self.warning = nagiosplugin.Range(opts.warning)
            self.critical = nagiosplugin.Range(opts.critical)

    def performance(self, metric, resource):
        if not opts.performance_data:
            return None
        return nagiosplugin.Performance(metric.name, metric.value, metric.uom,
                                        self.warning, self.critical,
                                        metric.min, metric.max)


class PerformanceDataContext(nagiosplugin.Context):

    def __init__(self):
        super(PerformanceDataContext, self).__init__('performance_data')

    def performance(self, metric, resource):
        """Derives performance data from a given metric.

        :param metric: associated metric from which performance data are
            derived
        :param resource: resource that produced the associated metric
            (may optionally be consulted)

        :returns: :class:`Perfdata` object
        """
        return nagiosplugin.Performance(label=metric.name, value=metric.value)


# Presentation: *Summary ######################################################


class SystemdSummary(nagiosplugin.Summary):
    """Format the different status lines. A subclass of `nagiosplugin.Summary
    <https://github.com/mpounsett/nagiosplugin/blob/master/nagiosplugin/summary.py>`_.
    """

    def ok(self, results) -> str:
        """Formats status line when overall state is ok.

        :param results: :class:`~nagiosplugin.result.Results` container
        :returns: status line
        """
        if opts.include_unit:
            for result in results.most_significant:
                if isinstance(result.context, UnitsContext):
                    return '{0}'.format(result)
        return 'all'

    def problem(self, results) -> str:
        """Formats status line when overall state is not ok.

        :param results: :class:`~.result.Results` container

        :returns: status line
        """
        summary = []
        for result in results.most_significant:
            if result.context.name in ['startup_time', 'units', 'timers']:
                summary.append(result)
        return ', '.join(['{0}'.format(result) for result in summary])

    def verbose(self, results) -> str:
        """Provides extra lines if verbose plugin execution is requested.

        :param results: :class:`~.result.Results` container

        :returns: list of strings
        """
        summary = []
        for result in results.most_significant:
            if result.context.name in ['startup_time', 'units', 'timers']:
                summary.append('{0}: {1}'.format(result.state, result))
        return summary


# Command line interface (argparse) ###########################################


def convert_to_regexp_list(regexp=None, unit_names=None,
                           unit_types=None):
    result = set()
    if regexp:
        for regexp in regexp:
            result.add(regexp)

    if unit_names:
        if isinstance(unit_names, str):
            unit_names = [unit_names]
        for unit_name in unit_names:
            result.add(unit_name.replace('.', '\\.'))

    if unit_types:
        types = SystemdUnitTypesList(*unit_types)
        result.add(types.convert_to_regexp())

    return result


def get_argparser():
    parser = argparse.ArgumentParser(
        prog='check_systemd',  # To get the right command name in the README.
        formatter_class=lambda prog: argparse.RawDescriptionHelpFormatter(prog, width=80),  # noqa: E501
        description=  # noqa: E251
        'Copyright (c) 2014-18 Andrea Briganti <kbytesys@gmail.com>\n'
        'Copyright (c) 2019-21 Josef Friedrich <josef@friedrich.rocks>\n'
        '\n'
        'Nagios / Icinga monitoring plugin to check systemd.\n',  # noqa: E501
        epilog=  # noqa: E251
        'Performance data:\n'
        '  - count_units\n'
        '  - startup_time\n'
        '  - units_activating\n'
        '  - units_active\n'
        '  - units_failed\n'
        '  - units_inactive\n',
    )

    parser.add_argument(
        '-v', '--verbose',
        action='count',
        default=0,
        help='Increase output verbosity (use up to 3 times).'
    )

    parser.add_argument(
        '-V', '--version',
        action='version',
        version='%(prog)s {}'.format(__version__),
    )

    # Scope: units ############################################################

    units = parser.add_argument_group(
        'Options related to unit selection',
        'By default all systemd units are checked. '
        'Use the option \'-e\' to exclude units\nby a regular expression. '
        'Use the option \'-u\' to check only one unit.'
    )

    units.add_argument(
        '-I', '--include',
        metavar='REGEXP',
        action='append',
        default=[],
        help='Include systemd units to the checks. This option can be '
             'applied multiple times, for example: -i mnt-data.mount -i '
             'task.service. Regular expressions can be used to include '
             'multiple units at once, for example: '
             '-e \'user@\\d+\\.service\'. '
             'For more informations see the Python documentation about '
             'regular expressions '
             '(https://docs.python.org/3/library/re.html).',
    )

    units.add_argument(
        '-u', '--unit', '--include-unit',
        type=str,
        metavar='UNIT_NAME',
        dest='include_unit',
        help='Name of the systemd unit that is being tested.',
    )

    units.add_argument(
        '--include-type',
        metavar='UNIT_TYPE',
        nargs='+',
        help='One or more unit types (for example: \'service\', \'timer\')',
    )

    units.add_argument(
        '-e', '--exclude',
        metavar='REGEXP',
        action='append',
        default=[],
        help='Exclude a systemd unit from the checks. This option can be '
             'applied multiple times, for example: -e mnt-data.mount -e '
             'task.service. Regular expressions can be used to exclude '
             'multiple units at once, for example: '
             '-e \'user@\\d+\\.service\'. '
             'For more informations see the Python documentation about '
             'regular expressions '
             '(https://docs.python.org/3/library/re.html).',
    )

    units.add_argument(
        '--exclude-unit',
        metavar='UNIT_NAME',
        nargs='+',
        help='Name of the systemd unit that is being tested.',
    )

    units.add_argument(
        '--exclude-type',
        metavar='UNIT_TYPE',
        action='append',
        help='One or more unit types (for example: \'service\', \'timer\')',
    )

    # Scope: timers ###########################################################

    timers = parser.add_argument_group('Timers related options')

    timers.add_argument(
        '-t', '--timers', '--dead-timers',
        dest='scope_timers', action='store_true',
        help='Detect dead / inactive timers. See the corresponding options '
             '\'-W, --dead-timer-warning\' and '
             '\'-C, --dead-timers-critical\'. '
             'Dead timers are detected by parsing the output of '
             '\'systemctl list-timers\'. '
             'Dead timer rows displaying \'n/a\' in the NEXT and LEFT '
             'columns and the time span in the column PASSED exceeds the '
             'values specified with the options \'-W, --dead-timer-warning\' '
             'and \'-C, --dead-timers-critical\'.'
    )

    timers.add_argument(
        '-W', '--timers-warning', '--dead-timers-warning',
        dest='timers_warning', metavar='SECONDS',
        type=float,
        default=60 * 60 * 24 * 6,
        help='Time ago in seconds for dead / inactive timers to trigger a '
             'warning state (by default 6 days).'
    )

    timers.add_argument(
        '-C', '--timers-critical', '--dead-timers-critical',
        dest='timers_critical', metavar='SECONDS',
        type=float,
        default=60 * 60 * 24 * 7,
        help='Time ago in seconds for dead / inactive timers to trigger a '
             'critical state (by default 7 days).'
    )

    # Scope: startup_time #####################################################

    startup_time = parser.add_argument_group('Startup time related options')

    startup_time.add_argument(
        '-n', '--no-startup-time',
        dest='scope_startup_time',
        action='store_false',
        default=True,
        help='Don’t check the startup time. Using this option the options '
             '\'-w, --warning\' and \'-c, --critical\' have no effect. '
             'Performance data about the startup time is collected, but '
             'no critical, warning etc. states are triggered.',
    )

    startup_time.add_argument(
        '-w', '--warning',
        default=60,
        metavar='SECONDS',
        help='Startup time in seconds to result in a warning status. The'
             'default is 60 seconds.',
    )

    startup_time.add_argument(
        '-c', '--critical',
        metavar='SECONDS',
        default=120,
        help='Startup time in seconds to result in a critical status. The'
             'default is 120 seconds.',
    )

    # Backend #################################################################

    acquisition = parser.add_argument_group('Monitoring data acquisition')
    acquisition_exclusive_group = acquisition.add_mutually_exclusive_group()

    acquisition_exclusive_group.add_argument(
        '--dbus',
        dest='data_source', action='store_const', const='dbus', default='cli',
        help='Use the systemd’s D-Bus API instead of parsing the text output '
             'of various systemd related command line interfaces to monitor '
             'systemd. At the moment the D-Bus backend of this plugin is '
             'only partially implemented.'
    )

    acquisition_exclusive_group.add_argument(
        '--cli',
        dest='data_source', action='store_const', const='cli',
        help='Use the text output of serveral systemd command line interface '
             '(cli) binaries to gather the required data for the monitoring '
             'process.'
    )

    # Performance data ########################################################

    perf_data = parser.add_argument_group('Performance data')
    perf_data_exclusive_group = perf_data.add_mutually_exclusive_group()

    perf_data_exclusive_group.add_argument(
        '-P', '--performance-data',
        dest='performance_data', action='store_true', default=True,
        help='Attach no performance data to the plugin output.'
    )

    perf_data_exclusive_group.add_argument(
        '-p', '--no-performance-data',
        dest='performance_data',  action='store_false',
        help='Attach performance data to the plugin output.'
    )

    return parser


def normalize_argparser(opts: argparse.Namespace) -> argparse.Namespace:
    if opts.data_source == 'dbus' and not is_gi:
        opts.data_source = 'cli'

    opts.include = convert_to_regexp_list(
        regexp=opts.include,
        unit_names=opts.include_unit,
        unit_types=opts.include_type
    )
    # del opts.include_unit
    del opts.include_type

    opts.exclude = convert_to_regexp_list(
        regexp=opts.exclude,
        unit_names=opts.exclude_unit,
        unit_types=opts.exclude_type
    )
    del opts.exclude_type
    del opts.exclude_unit

    return opts


@nagiosplugin.guarded(verbose=0)
def main():
    """The main entry point of the monitoring plugin. First the command line
    arguments are read into the variable ``opts``. The configuration of this
    ``opts`` object decides which instances of the `Resource
    <https://github.com/mpounsett/nagiosplugin/blob/master/nagiosplugin/resource.py>`_,
    `Context
    <https://github.com/mpounsett/nagiosplugin/blob/master/nagiosplugin/context.py>`_
    and `Summary
    <https://github.com/mpounsett/nagiosplugin/blob/master/nagiosplugin/summary.py>`_
    subclasses are assembled in a list called ``tasks``. This list is passed
    the main class of the ``nagiosplugin`` library: the `Check
    <https://nagiosplugin.readthedocs.io/en/stable/api/core.html#nagiosplugin-check>`_
    class.
    """
    global opts
    opts = get_argparser().parse_args()
    opts = normalize_argparser(opts)

    global unit_cache
    if opts.data_source == 'dbus':
        unit_cache = DbusUnitCache()
    else:
        unit_cache = CliUnitCache()

    tasks = [
        UnitsResource(),
        UnitsContext(),
        SystemdSummary(),
    ]

    if opts.scope_startup_time:
        tasks += [
            StartupTimeResource(),
            StartupTimeContext(),
        ]

    if opts.scope_timers:
        tasks += [
            TimersResource(),
            TimersContext(),
        ]

    if opts.performance_data:
        tasks += [
            PerformanceDataResource(),
            PerformanceDataDataSourceResource(),
            PerformanceDataContext(),
        ]

    check = nagiosplugin.Check(*tasks)
    check.main(opts.verbose)


if __name__ == '__main__':
    main()
