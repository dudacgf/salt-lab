#!py
import re
import logging

log = logging.Logger(__name__)

#
# use pillar 'locale' and 'keymap' dict values to configure minion locale settings
#
def run():
    
    config = {}

    # only works in Debian or RedHat distribution families (never used any other, sorry)
    osf = __grains__['os_family']
    if osf not in ['Debian', 'RedHat']:
        config['nothing to do'] = {
            'test.show_notification': [
                 {'text': '*** host pillar has no TDNS zones settings ***'},
            ],
        }
        return config

    # get locale data from pillar
    locale_ = __pillar__['locale']
    keymap = __pillar__['keymap']
    (lang, variation, encoding) = re.match('^([a-z]*)_?([A-Z]*)\.*(.*)$', locale_).groups()

    # Debian: uncomment locale line in /etc/locale.gen and generate new locales
    if osf == 'Debian':
        config['locales'] = 'pkg.installed'

        config['/etc/locale.gen'] = {
            'file.replace': [
                {'pattern': f"'^# {locale_}'"},
                {'repl': f"'{locale_}'"},
            ],
        }
        config['locale-gen'] = {
            'cmd.run': [
                {'require': [{'file': '/etc/locale.gen'}]},
            ],
        }
        config['pre-localectl'] = {
            'cmd.run': [
                {'name': 'update-locale'},
                {'require': [{'cmd': 'locale-gen'}]},
            ],
        }

        config['console-data'] =  'pkg.installed' 
        config['create-keymaps-dir'] = {
            'cmd.run': [
                {'name': 'mkdir -p /usr/share/kbd/keymaps'},
                {'require': [{'pkg': 'console-data'}]},
            ],
        }
        config['copy-keymaps'] = {
            'cmd.run': [
                {'name': f'gunzip -c /usr/share/keymaps/i386/qwerty/{keymap}.kmap.gz > /usr/share/kbd/keymaps/br-abnt2.map'},
                {'require': [{'cmd': 'create-keymaps-dir'}]},
            ],
        }
        config[f'loadkeys {keymap}'] =  'cmd.run' 

        config['set-locale'] = {
            'cmd.run': [
                {'name': f'localectl set-locale LANG={locale_} LANGUAGE={locale_}'},
                {'require': ['pre-localectl']},
            ],
        }
        config[f'localectl set-x11-keymap {keymap}'] = {
            'cmd.run': [
                {'require': [{'cmd': 'set-locale'}]},
            ],
        }
        config[f'localectl set-keymap {keymap}'] = {
            'cmd.run': [
                {'require': [{'cmd': 'set-locale'}]},
            ],
        }

    # RedHat: install needed locale and language files
    else:
        packages = __salt__['cmd.run']('dnf -q list langpacks-{}*'.format(lang)).split('\n')
        del packages[0]
        packages = [re.sub(r' .*', '', x) for x in packages]
        packages.append('glibc-langpack-{}'.format(lang))
        setpkg = set(packages)
        packages = list(setpkg)

        config['pre-localectl'] = {
            'pkg.installed': [
                {'pkgs': packages }
            ],
        }

        config['set-locale'] = {
            'cmd.run': [
                {'name': f'localectl set-locale LANG={locale_} LANGUAGE={locale_}'},
                {'require': ['pre-localectl']},
            ],
        }

        config[f'localectl set-keymap {keymap}'] = {
            'cmd.run': [
                {'require': [{'cmd': 'set-locale'}]},
            ],
        }

    return config
            
