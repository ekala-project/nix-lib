{ lib }:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    ints
    listOf
    nullOr
    port
    str
    submodule
    ;

  /**
    Health probe configuration for a service port.

    Note: field names use `snake_case` (`healthy_threshold`,
    `unhealthy_threshold`), not camelCase.

    # Type

    ```
    healthCheckOpts :: submodule
    ```

    # Examples

    ```nix
    {
      path = "/health";
      interval = 10;
      timeout = 5;
      healthy_threshold = 3;
      unhealthy_threshold = 3;
    }
    ```
  */
  healthCheckOpts = {
    options = {
      path = mkOption {
        type = nullOr str;
        default = null;
        example = "/health";
        description = ''
          HTTP path to probe. When set, enables HTTP health checking.
          null disables path-based probing (TCP-only check).
        '';
      };

      interval = mkOption {
        type = ints.unsigned;
        default = 10;
        description = "Seconds between probes.";
      };

      timeout = mkOption {
        type = ints.unsigned;
        default = 5;
        description = "Per-probe timeout in seconds.";
      };

      healthy_threshold = mkOption {
        type = ints.unsigned;
        default = 3;
        description = "Consecutive successes required to be considered healthy.";
      };

      unhealthy_threshold = mkOption {
        type = ints.unsigned;
        default = 3;
        description = "Consecutive failures required to be considered unhealthy.";
      };
    };
  };
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

  inherit healthCheckOpts;

  /**
    Per-port network configuration including health probes.

    Consumed by DNS service discovery (SRV records), L7 reverse proxy
    (hostname-based routing), prometheus-scrape module (metrics endpoint
    detection), and deployment health gates.

    When `liveness`, `readiness`, or `startup` probes are specified they
    take precedence over the unified `healthCheck`. If only `healthCheck`
    is specified it is used for both liveness and readiness.

    # Type

    ```
    portContract :: submodule
    ```

    # Examples

    ```nix
    ports.http = {
      port = 8080;
      hostname = "api.example.com";
      liveness = { path = "/health"; };
      readiness = { path = "/ready"; interval = 5; };
    };
    ```
  */
  portContract = {
    options = {
      port = mkOption {
        type = port;
        description = "Port number (1-65535).";
      };

      protocol = mkOption {
        type = nullOr str;
        default = null;
        example = "tcp";
        description = ''
          Protocol identifier (e.g., "tcp", "http").
          null defaults to TCP.
        '';
      };

      hostname = mkOption {
        type = nullOr str;
        default = null;
        example = "api.example.com";
        description = ''
          Virtual hostname for L7 proxy routing.
          null means no hostname-based routing for this port.
        '';
      };

      healthCheck = mkOption {
        type = nullOr (submodule healthCheckOpts);
        default = null;
        description = ''
          Unified health check. Used for both liveness and readiness
          when separate probes are not specified.
        '';
      };

      liveness = mkOption {
        type = nullOr (submodule healthCheckOpts);
        default = null;
        description = ''
          Liveness probe. Failures trigger a service restart.
          Takes precedence over the unified healthCheck.
        '';
      };

      readiness = mkOption {
        type = nullOr (submodule healthCheckOpts);
        default = null;
        description = ''
          Readiness probe. Failures remove the instance from load
          balancing but do not restart it.
          Takes precedence over the unified healthCheck.
        '';
      };

      startup = mkOption {
        type = nullOr (submodule healthCheckOpts);
        default = null;
        description = ''
          Startup probe. Suppresses liveness checks until the service
          finishes initializing. Once the startup probe passes,
          liveness takes over.
        '';
      };
    };
  };
}
