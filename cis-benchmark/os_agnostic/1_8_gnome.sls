###########
## DEBIAN 12 - THIS APPEARS AT 1.7
## UBUNTU 22.04 - THIS APPEARS AT 1.8
## REDHAT 9 - THIS APPEARS AT 1.8
##########

### 1.8 Gnome Display Manager
{% if not pillar['apps']['gnome-desktop'] | default(False) %}
## 1.8.1 Ensure GNOME Display Manager is removed 
{% set gdm = salt.grains.filter_by({'Debian': 'gdm3', 'RedHat': 'gdm') %}
{{ gdm }}: pkg.purged

## 2.2.1 Ensure X Window System is not installed (antecipated)
{{ pillar.pkg_data.gnome.xserver }}: pkg.purged

'{{ pillar.pkg_data.packager }} autoremove -y': cmd.run

{% else %}
## 1.8.2 Ensure GDM login banner is configured 
/etc/dconf/profile/gdm:
  file.managed:
    - contents: |
          user-db:user
          system-db:gdm
          file-db:/usr/share/gdm/greeter-dconf-defaults

/etc/dconf/db/gdm.d/01-banner-message:
  file.managed:
    - makedirs: True
    - contents:
          [org/gnome/login-screen]
          banner-message-enable=true
          banner-message-text='--                                                                        --\n-- Apenas uso autorizado. Toda atividade pode ser monitorada e reportada. --\n--                                                                        --\n--    Authorized uses only. All activity may be monitored and reported.   --\n--                                                                        --\n--           I've read & consent to terms in IS user agreem't             --\n--                                                                        --'

## 1.8.3 Ensure GDM disable-user-list option is disabled
/etc/dconf/db/gdm.d/00-login-screen:
  file.managed:
    - makedirs: True
    - contents:
          [org/gnome/login-screen]
          disable-user-list=true

## 1.8.4 Ensure GDM screen locks when the user is idle
/etc/dconf/profile/user:
  file.managed:
    - contents: |
          user-db:user
          system-db:local

/etc/dconf/db/local.d/00-screensaver:
  file.managed:
    - makedirs: True
    - contents: |
          [org/gnome/desktop/session]
          idle-delay=uint32 900
          [org/gnome/desktop/screensaver]
          lock-enabled=true
          lock-delay=uint32 5

## 1.8.5 Ensure GDM screen locks cannot be overridden
/etc/dconf/db/local.d/locks/00-screensaver:
  file.managed:
    - makedirs: True
    - contents: |
          /org/gnome/desktop/screensaver/idle-delay
          /org/gnome/desktop/screensaver/lock-delay
          /org/gnome/desktop/screensaver/lock-enabled

## 1.8.6 Ensure GDM automatic mounting of removable media is disabled
## 1.8.8 Ensure GDM autorun-never is enabled
/etc/dconf/db/local.d/00-media-automount:
  file.managed:
    - makedirs: True
    - contents: |
          [org/gnome/desktop/media-handling]
          automount=false
          automount-open=false
          autorun-never=true

## 1.8.7 Ensure GDM disabling automatic mounting of removable is not overriden
## 1.8.9 Ensure GDM autorun-never is not overridden
/etc/dconf/db/local.d/locks/00-media-automount:
  file.managed:
    - makedirs: True
    - contents: |
          /org/gnome/desktop/media-handling/automount
          /org/gnome/desktop/media-handling/automount-open
          /org/gnome/desktop/media-handling/automount-open
#gsettings set org.gnome.desktop.media-handling automount false: cmd.run

## 1.8.10 Ensure XDCMP is not enabled 
{{ pillar.pkg_data.gnome.conf }}:
  file.replace:
    - pattern: '(\[xdmcp\]\n)Enable.*=.*true'
    - repl: '\1Enable=false'

## updates dconf
dconf update: cmd.run

## 2.2.3 Ensure CUPS is not installed 
cups: pkg.purged

{% endif %}
