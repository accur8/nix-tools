{
  fetchurl,
  linkFarm,
  jdk8,
  jdk11,
  jdk17,
  stdenv,
  unzip,
}: {
  name,
  mainClass,
  sbtDependenciesFn,
  jvmArgs ? [],
  appArgs ? [],
  webappExplode ? false,
  javaVersion ? "11",
}:
  
  let

    # name = "a8-sync";
    # mainClass = "a8.sync.demos.LongQueryDemo";
    # sbtDependenciesFn = import ./sbt-deps.nix;
    # jvmArgs = ["-Xmx4g"];
    # webappExplode = true;

    fetcherFn = 
      dep: (
        fetchurl {
          url = dep.url;
          sha256 = dep.sha256;
        }
      );

    jdk = 
      if javaVersion == "8" then jdk8
      else if javaVersion == "11" then jdk11
      else if javaVersion == "17" then jdk17
      else abort("expected javaVersion = [ 8 | 11 | 17 ] got ${javaVersion}")
    ;

    artifacts = sbtDependenciesFn fetcherFn;

    linkFarmEntryFn = drv: { name = drv.name; path = drv; };

    classpathBuilder = linkFarm name (map linkFarmEntryFn artifacts);

    args = builtins.concatStringsSep " " (jvmArgs ++ [mainClass] ++ appArgs);

    webappExploder = 
      if webappExplode then
        ''
          echo exploding webapp-composite folder
          for jar in ${classpathBuilder}/*.jar
          do
            ${unzip}/bin/unzip $jar "webapp/*" -d $out/webapp-composite 2> /dev/null 1> /dev/null || true
          done
        ''
      else
        ""
    ;

  in

    stdenv.mkDerivation {
      name = name;
      src = ./.;
      installPhase = ''

        mkdir -p $out/bin

        # create link to jdk bin so that top and other tools show the process name as something meaningful
        ln -s ${jdk}/bin/java $out/bin/${name}j

        # create link to lib folder derivation
        ln -s ${classpathBuilder} $out/lib

        LAUNCHER=$out/bin/${name}

        # setup launcher script
        cp ./java-launcher-template $LAUNCHER
        chmod +x $LAUNCHER
        substituteInPlace $LAUNCHER \
          --replace _name_ ${name} \
          --replace _out_ $out \
          --replace _args_ "${args}"

      '' + webappExploder;
    }
