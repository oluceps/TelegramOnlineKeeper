# Telegram User Online Keeper

Timeline Forensics Preventation

## usage

Option 1: Set `$API_ID` & `$API_HASH` then `python main.py` in console.

Option 2: As option 1 but set only `$SESSION_STRING`. [Details about session string](https://docs.pyrogram.org/topics/storage-engines#persisting-sessions)

Option 3: If using NixOS, import the `nixosModule` and set the `environmentFile` option:

```nix
services.online-keeper.instances = [
  {
    name = "example";
    environmentFile = "/home/user/.env";
  }
];
```

The `environmentFile` must contain environments either in option 1 or 2. [Details about EnvironmentFile](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#EnvironmentFile=)
