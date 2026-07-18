{ lib }:

let
  inherit (lib) mkOption;
  inherit (lib.types) listOf str;
in
{
  /**
    Service-to-service authorization policy.

    Consumed by nftables identity rules (inter-service traffic on
    WireGuard), mTLS policy (SPIFFE certificate SAN validation),
    and ekafleet workload attestation.

    # Type

    ```
    identityContract :: submodule
    ```

    # Examples

    ```nix
    identity = {
      allowedCallers = [ "nginx" "api-gateway" ];
      allowedTargets = [ "database" "cache" ];
    };
    ```
  */
  identityContract = {
    options = {
      allowedCallers = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "nginx" "api-gateway" ];
        description = ''
          SPIFFE IDs of services permitted to call this service.
          Used for nftables inter-service rules and mTLS policy.
          Empty list means no callers are explicitly permitted.
        '';
      };

      allowedTargets = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "database" "cache" ];
        description = ''
          SPIFFE IDs of services this service is permitted to call.
          Used for egress policy enforcement.
          Empty list means no targets are explicitly permitted.
        '';
      };
    };
  };
}
