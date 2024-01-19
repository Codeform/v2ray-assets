#!/usr/bin/env -S nix shell nixpkgs#jaq nixpkgs#alejandra --command bash

# json=$(cat example.json)
json=$(curl -Ls https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest)

upload_time=$(jaq .published_at <<< "$json")

upload_timestamp=$(date -u -d ${upload_time:1:-1} +%s)

old_version=$(grep -Po '(?<= version = ")\d+' flake.nix)
year=${old_version:0:4}
mon=${old_version:4:2}
day=${old_version:6:2}
hour=${old_version:8:2}
min=${old_version:10:2}
old_timestamp=$(date "+%s" -d "$year/$mon/$day $hour:$min")
version=$(jaq .tag_name <<< "$json")

echo "current version is $old_version, upstream version is ${version:1:-1}"

if [ $((upload_timestamp-old_timestamp)) -gt $((7*24*60*60)) ]; then
  echo "outdated for at least one week, updating"
  geoip_url=$(jaq '.assets | map(select(.name == "geoip.dat")) | .[0].browser_download_url' <<< "$json")
  geoip_hash_url=$(jaq '.assets | map(select(.name == "geoip.dat.sha256sum")) | .[0].browser_download_url' <<< "$json")
  geosite_url=$(jaq '.assets | map(select(.name == "geosite.dat")) | .[0].browser_download_url' <<< "$json")
  geosite_hash_url=$(jaq '.assets | map(select(.name == "geosite.dat.sha256sum")) | .[0].browser_download_url' <<< "$json")

  geoip_hash=$(curl -Ls ${geoip_hash_url:1:-1} | cut -f 1 -d ' ')
  geoip_hash=$(nix hash to-sri --type sha256 $geoip_hash)
  geosite_hash=$(curl -Ls ${geosite_hash_url:1:-1} | cut -f 1 -d ' ')
  geosite_hash=$(nix hash to-sri --type sha256 $geosite_hash)
  sed -i "s/version = \"[^\"]*\"/version = \"${version:1:-1}\"/" flake.nix
  sed -i "s|geositeHash = \"[^\"]*\"|geositeHash= \"$geosite_hash\"|" flake.nix
  sed -i "s|geoipHash = \"[^\"]*\"|geoipHash = \"$geoip_hash\"|" flake.nix

  alejandra flake.nix &>/dev/null

  nix flake update

  git add .
  git commit -m '[chore] Bump V2Ray assets: '$old_version' -> '${version:1:-1}
else
  echo "too soon to update"
fi
