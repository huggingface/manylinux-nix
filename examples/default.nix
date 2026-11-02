{
  lib,
  pkgs,
  manylinux_2_28,
}:

let
  hooks = import ./hooks { inherit lib pkgs; };

  callExample = path: (import path { inherit pkgs manylinux_2_28 hooks; }).dist;
in
import ./hooks/tests { inherit lib pkgs; }
// {
  # Exmaples of building real-world Python packages as manylinux_2_28 wheels.
  example-lxml = callExample ./lxml;
  example-pycryptodome = callExample ./pycryptodome;
}
