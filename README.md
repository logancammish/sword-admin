# sword-admin

This model has been converted from `sword-admin.rbxm` into a Rojo 7 project.
Editable Luau and Rojo metadata live in `src`; binary `.rbxm` files inside that
directory preserve Roblox instances that cannot be represented faithfully as
plain source or JSON.

The original `sword-admin.rbxm` is retained as a reference copy and is not used
by `default.project.json`.

## Usage

With Rojo installed (the version is pinned in `rokit.toml`):

```sh
rojo serve
```

To build the model without Roblox Studio:

```sh
mkdir -p build
rojo build --output build/sword-admin.rbxm
```
