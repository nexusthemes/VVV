#!/bin/bash
# set -x

## VARIABLES
cwd=$(pwd)
nexusconf="${cwd}/nexus-conf"
vvvprov="${cwd}/provision"
wpstable="${cwd}/www/wordpress-default"
resources="${wpstable}/resources"
theme_dir="${wpstable}/wp-content/themes"
plugins_dir="${wpstable}/wp-content/plugins"

PRE="==> nexus-themes: "
LGR="\e[32m${PRE}"

### FUNCTIONS
nexus_setup() {
  local nxs_vgt
  local nxs_prov
  local orig_vgt
  local orig_prov
  nxs_vgt="${nexusconf}/nexus-vagrantfile"
  nxs_prov="${nexusconf}/nexus-provision.sh"
  orig_vgt="${cwd}/Vagrantfile"
  orig_prov="${vvvprov}/provision.sh"
  if ! diff -qs "$nxs_vgt" "$orig_vgt" || ! diff -qs "$nxs_prov" "$orig_prov" ; then
    cp "$nxs_vgt" "$orig_vgt"
    cp "$nxs_prov" "$orig_prov"
    echo -e "${LGR}Nexus VVV config files set."
  else
    echo -e "${LGR}Nexus VVV config files already set."
  fi
}

vgt_up() {
  vagrant up --provision
}

rsc_dir() {
  if [[ ! -d "$resources" ]]; then
    mkdir -p "$resources"
    echo -e "${LGR}Resources directory created."
  else
    echo -e "${LGR}Resources directory already exists."
  fi
}

install_theme() {
  local nxs_theme
  nxs_theme=$(find "$theme_dir" -name "blogger*" -print)  
  if [[ ! -d "$nxs_theme" ]]; then
    curl -Lk -o "$resources/blogger.zip" "http://89.18.175.44/nexusthemesv4/wp-content/uploads/sites/22/downloads/2015/03/blogger.zip" 
    vagrant ssh -c "cd /srv/www/wordpress-default && wp theme install ./resources/blogger.zip --activate"
    echo -e "${LGR}Nexus Blogger theme installed and activated."
  else
    echo -e "${LGR}Nexus Blogger theme already installed and activated."
  fi
}

install_fwk() {
  local nxs_theme
  local nxs_fwk
  nxs_theme=$(find "$theme_dir" -name "blogger*" -print)
  nxs_fwk=$(find "$nxs_theme" -name "nexusframework" -print)
  if [[ -d "$nxs_fwk" ]]; then
    mv -f "$nxs_fwk/stable" "$resources"
    git clone "git@github.com:nexusthemes/nexusframework.git" "$nxs_fwk/"
    sed -e "13 c \ \ define('NXS_FRAMEWORKVERSION', \"nexusframework\");" "$nxs_theme/functions.php" > "$resources/functions.txt"
    cp -f "$resources/functions.txt" "$nxs_theme/functions.php"
    echo -e "${LGR}Nexus Framework set."
  else
    echo -e "${LGR}Nexus Framework already set."
  fi
}

install_woobridge() {
  local nxs_woo
  nxs_woo="$plugins_dir/nxs-woobridge"
  if [[ ! -d "$nxs_woo" ]]; then
    vagrant ssh -c "cd /srv/www/wordpress-default && wp plugin install woocommerce --activate"
    git clone "git@github.com:nexusthemes/nxs-woobridge.git" "$nxs_woo"
    vagrant ssh -c "cd /srv/www/wordpress-default && wp plugin activate nxs-woobridge"
    echo -e "${LGR}Nexus Woobridge set."
  else
    echo -e "${LGR}Nexus Woobridge already set."
  fi
}

### SCRIPT
echo -e "${LGR}Current working directory: $cwd"
echo -e "${LGR}Setting up Nexus Development environment."
nexus_setup
vgt_up
rsc_dir
install_theme
install_fwk
install_woobridge
echo -e "${LGR}Nexus Development environment done!"
