#!py
import re

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
        config[f'loadkeys {keymap}'] =  'cmd.run' 

    # RedHat: install needed locale and language files
    else:
        packages = __salt__['cmd.run']('dnf -q list langpacks-{}*'.format(lang)).split('\n')
        del packages[0]
        packages = [re.sub(r' .*', '', x) for x in packages]
        packages.append('glibc-langpack-{}'.format(lang))

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
            
