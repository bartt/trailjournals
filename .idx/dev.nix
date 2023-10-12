{pkgs}: {
  # Use https://search.nixos.org/packages?channel=unstable to  find packages
  packages = [
    pkgs.nodejs_18
  ];

  # sets environment variables in the workspace
  env = {
    # PORT = 9292;
  };

  idx = {
    # search for the extension on https://open-vsx.org/ and use "publisher.id"
    extensions = [];

    # preview configuration, identical to monospace.json
    previews = {
      enable = true;
      previews = [
        {
          command = [
            "npm" 
            "run" 
            "dev"
            "--"
            "--port"
            "$PORT"
            "--host"
            "0.0.0.0"
          ];
          id = "web";
          manager =  "web";
        }
      ];
    };
  };
}