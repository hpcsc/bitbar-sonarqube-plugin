# BitBar Sonarqube Status

A plugin for [BitBar](https://github.com/matryer/bitbar) to display statistics from Sonarqube projects

![Screenshot](https://i.imgur.com/foGh0kq.png)

## Setup

- Clone this repository and symlink the script in this repo to your BitBar plugins folder:

    ```
    ln -s $PWD/src/sonarqube-status.1h.sh path-to-your-bitbar-plugin-folder/sonarqube-status.1h.sh
    ```

- Copy `sample.config.json` to your BitBar plugins folder and rename it to `.bitbar-sonarqube-plugin.json`:

    ```
    cp ./sample-config.json path-to-your-bitbar-plugin-folder/.bitbar-sonarqube-plugin.json
    ```

    Notice the dot in front of json file name? This is to prevent BitBar from executing this file

- Update configuration in your `bitbar-sonarqube-plugin.json`
    - `token` field:
        Follow instruction at https://docs.sonarqube.org/latest/user-guide/user-token/ to generate an user token

    - `from`/`until` fields:

        The plugin will not make the call to TeamCity server if the current time is not within `from` and `until` timespan. Both `from` and `until` are optional. When they are present, they must follow the format of `HH:mm` where `HH` is in 24h format (if the hour component is less than 10, prefix it with 0 like `06`). The plugin only uses string comparison to compare the time for simplicity and therefore will not be able to handle complicated/invalid time pattern.

    - `daysOfWeek` field:

        Comma-separated string of days of week that the plugin is supposed to run. Valid values are 1-7 (1 is Monday, 7 is Sunday)

## Run Tests

This project uses [bats](https://github.com/bats-core/bats-core) and several of its additional libraries like [bats-assert](https://github.com/bats-core/bats-assert) and [bats-support](https://github.com/bats-core/bats-support) for testing

To run the test locally:

```
git submodule update --init --remote    # pull bats dependency libraries
./batect test                           # run tests using batect. Tests are run in bats container
```
