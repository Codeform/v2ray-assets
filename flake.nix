{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) fetchurl lib;
  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation rec {
      name = "v2ray-assets";
      version = "202505282213";
      srcs = let
        geositeRev = version;
        geositeHash = "sha256-DGA761u7O5ZHbEW5opj+hRXou3oMFbFMlK8arP7VCW0=";
        geoipRev = version;
        geoipHash = "sha256-MOGovqFWEHgd/J1tB92F7OjgqbZHFW4uNH9HKn/Cb7o=";
      in [
        (fetchurl {
          url = "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${geoipRev}/geoip.dat";
          hash = geoipHash;
        })

        (fetchurl {
          url = "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${geositeRev}/geosite.dat";
          hash = geositeHash;
        })
      ];

      sourceRoot = ".";

      phases = ["installPhase"];

      installPhase = ''
        mkdir -p $out/share/v2ray

        for _src in $srcs; do
          cp "$_src" $out/share/v2ray/$(stripHash "$_src")
        done
      '';

      meta = with lib; {
        description = "🦄 🎃 👻 V2Ray 路由规则文件加强版，可代替 V2Ray 官方 geoip.dat 和 geosite.dat，兼容 Shadowsocks-windows、Xray-core、Trojan-Go 和 leaf。Enhanced edition of V2Ray rules dat files, compatible with Xray-core, Shadowsocks-windows, Trojan-Go and leaf.";
        homepage = "https://github.com/Loyalsoldier/v2ray-rules-dat";
        license = licenses.gpl3;
      };
    };
  };
}
