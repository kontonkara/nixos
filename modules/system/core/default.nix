{ ... }:

{
  system = {
    stateVersion = "26.05";
  };

  nix = {
    settings = {
      experimental-features = [ 
        "nix-command"
        "flakes"
      ];
    };
  };
  
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}