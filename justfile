default:
    @just --list

# Apply home-manager config for a given profile
switch profile="work-macbook":
    home-manager switch --flake '.#{{profile}}'

# Bootstrap on a fresh machine (no home-manager installed yet)
bootstrap profile="work-macbook":
    nix run home-manager -- switch --flake '.#{{profile}}'

# Update all flake inputs to latest versions
update:
    nix flake update

# Check that the flake evaluates correctly
check:
    nix flake check
