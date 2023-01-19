# Interfaces

## Motivation

Often, multiple maps have the same structure. You can create a common super class for that. This allows you to write cleaner code.

Add the `(interface=<Interface Name>)` to the container node.

```json
{
  "onboarding": {
    "whatsNew(interface=ChangeData)": {
      "v2": {
        "title": "New in 2.0",
        "rows": [
          "Add sync"
        ]
      },
      "v3": {
        "title": "New in 3.0",
        "rows": [
          "New game modes",
          "And a lot more!"
        ]
      }
    }
  }
}
```

The generated mixin may look like this:

```dart
mixin ChangeData {
  String get title;
  List<String> get rows;
}
```

## Configuration

### Modifier

The quickest method to get started with interfaces. You don't need to touch the config file at all.

Just add the `(interface=MyInterface)` modifier to target a container of interfaces which is the most common usage. It can be applied to maps and lists.

Alternatively, add `(singleInterface=MyInterface)` to target a single interface. This can only be applied to a map.

Attributes of the desired interface will be inferred automatically.

### Config file

This method allows for a more fine-grained configuration.

#### Example

```yaml
# Config
interfaces:
  MyInterface: about.changelog.* # shorthand
  MyOtherInterface: # full config
    paths:
      - onboarding.whatsNew.*
    attributes:
      - String title
      - String? content
```

#### Paths

You can either specify one node or a container of nodes.

| Example                | Description               |
|------------------------|---------------------------|
| `onboarding.firstPage` | single node               |
| `onboarding.pages.*`   | container (non-recursive) |

```json
{
  "onboarding": {
    "firstPage": {
      "title": "hi",
      "content": "hi"
    },
    "pages": [
      {
        "title": "hi",
        "content": "hi"
      },
      {
        "title": "hi",
        "content": "hi"
      },
      {
        "title": "hi",
        "content": "hi"
      }
    ]
  }
}
```

#### Attributes

Attributes can be specified in multiple ways.

| Example                              | Description               |
|--------------------------------------|---------------------------|
| `String title`                       | simple version            |
| `String greet(firstName, lastName)`  | with parameters           |
| `String? greet(firstName, lastName)` | optional                  |
| `List<Feature> features`             | list of another interface |

## Attribute inference

Attributes of the interface are inferred in the following cases:

- usage of modifiers
- leaving out attributes in config

```json5
{
  "first(interface=MyInterface)": {
    "i": {
      "a": "",
      "b": ""
    },
    "j": {
      "a": "",
      "b": "",
      "c": ""
    }
  },
  "second(interface=MyInterface)": {
    "k": {
      "a": ""
    },
    "l": {
      "a": "",
      "c": ""
    }
  }
}
```

In the given example, the first interface will be inferred to `a, b, c?`.

The second interface will be inferred to `a, c?`.

Because both of them share the same interface name `MyInterface`, these attributes get merged.

The final interface is `a, b?, c?`.

For reference, if you use the following config, you will get the same result:

```yaml
# Config
interfaces:
  MyInterface:
    paths:
      - first.*
      - second.*
```