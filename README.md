# Telegram User Online Keeper

Timeline Forensics Preventation

## usage

Set `$API_ID` & `$API_HASH` then `cargo run` in console.

If using NixOS, import the `nixosModule` and set the `sessionFile` `environmentFile` option:

```nix
services.online-keeper.instances = [
  {
    name = "example";
    sessionFile = "/home/user/user.session";
    environmentFile = "/home/user/.env";
  }
];
```
`environmentFile` MUST contain `$API_ID` & `$API_HASH`. [Details about EnvironmentFile](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#EnvironmentFile=)
