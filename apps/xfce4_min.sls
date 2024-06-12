#
## lu_min.sls instala um lubuntu minimo que permita ler um pdf
#

#
# instala os pacotes mais básicos o possível
install_minimal_lubuntu:
  pkg.installed:
    - pkgs:
      - xfce4
      - slim
      - xorg
      - evince

