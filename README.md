# Telegram User Online Keeper

Timeline Forensics Preventation

## usage

Option 1: Set `$API_ID` & `$API_HASH` then `python main.py` in console.

Option 2: Set `$SESSION_STRING` then run. [Details about session string](https://docs.pyrogram.org/topics/storage-engines#persisting-sessions)

Option 3: If using NixOS, import the `nixosModule` and set the `environmentFile` option:

```nix
      online-keeper.instances = [
        {
          name = "example";
          environmentFile = "/home/user/.env";
        }
      ];
```

The `environmentFile` contains options either in option 1 or 2.
