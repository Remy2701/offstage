import gleam/list
import gleam/option.{type Option, None, Some}
import offstage/dynamic/spec.{type Spec}
import offstage/openapi/openapi

/// A type representing the various OpenAPI data types and their associated metadata.
pub type OpenAPIType {
  String(
    format: Option(String),
    default: Option(Spec),
    examples: List(Spec),
    pattern: Option(String),
    enum: List(String),
    title: Option(String),
  )
  Integer(
    format: Option(String),
    default: Option(Spec),
    examples: List(Spec),
    title: Option(String),
  )
  Number(
    format: Option(String),
    default: Option(Spec),
    examples: List(Spec),
    min: Option(Spec),
    max: Option(Spec),
    title: Option(String),
  )
  Boolean(
    format: Option(String),
    default: Option(Spec),
    examples: List(Spec),
    title: Option(String),
  )
  Array(
    format: Option(String),
    default: Option(Spec),
    examples: List(Spec),
    items: Option(OpenAPIType),
    title: Option(String),
  )
  Object(
    format: Option(String),
    default: Option(Spec),
    examples: List(Spec),
    properties: List(ObjectProperty),
    title: Option(String),
  )
  Null
  Option(of: OpenAPIType)
  OneOf(values: List(OpenAPIType))
}

pub type ObjectProperty {
  ObjectProperty(name: String, type_: OpenAPIType, required: Bool)
}

/// Specify the format for an OpenAPI type.
pub fn format(type_: OpenAPIType, format fmt: String) -> OpenAPIType {
  case type_ {
    String(..) -> String(..type_, format: Some(fmt))
    Integer(..) -> Integer(..type_, format: Some(fmt))
    Number(..) -> Number(..type_, format: Some(fmt))
    Boolean(..) -> Boolean(..type_, format: Some(fmt))
    Array(..) -> Array(..type_, format: Some(fmt))
    Object(..) -> Object(..type_, format: Some(fmt))
    Null -> Null
    Option(of) -> Option(format(of, fmt))
    OneOf(values) -> OneOf(values: list.map(values, format(_, fmt)))
  }
}

/// Specify the default value for an OpenAPI type.
pub fn default(type_: OpenAPIType, default dflt: Spec) -> OpenAPIType {
  case type_ {
    String(..) -> String(..type_, default: Some(dflt))
    Integer(..) -> Integer(..type_, default: Some(dflt))
    Number(..) -> Number(..type_, default: Some(dflt))
    Boolean(..) -> Boolean(..type_, default: Some(dflt))
    Array(..) -> Array(..type_, default: Some(dflt))
    Object(..) -> Object(..type_, default: Some(dflt))
    Null -> Null
    Option(of) -> Option(default(of, dflt))
    OneOf(values) -> OneOf(values: list.map(values, default(_, dflt)))
  }
}

/// Specify an example value for an OpenAPI type.
pub fn example(type_: OpenAPIType, example ex: Spec) -> OpenAPIType {
  case type_ {
    String(..) -> String(..type_, examples: list.append(type_.examples, [ex]))
    Integer(..) -> Integer(..type_, examples: list.append(type_.examples, [ex]))
    Number(..) -> Number(..type_, examples: list.append(type_.examples, [ex]))
    Boolean(..) -> Boolean(..type_, examples: list.append(type_.examples, [ex]))
    Array(..) -> Array(..type_, examples: list.append(type_.examples, [ex]))
    Object(..) -> Object(..type_, examples: list.append(type_.examples, [ex]))
    Null -> Null
    Option(of) -> Option(example(of, ex))
    OneOf(values) -> OneOf(values: list.map(values, example(_, ex)))
  }
}

/// Specify a pattern for an OpenAPI string type.
pub fn pattern(type_: OpenAPIType, pattern p: String) -> OpenAPIType {
  case type_ {
    String(..) -> String(..type_, pattern: Some(p))
    Option(of) -> Option(pattern(of, p))
    _ -> type_
  }
}

pub fn min(type_: OpenAPIType, min m: Spec) -> OpenAPIType {
  case type_ {
    Number(..) -> Number(..type_, min: Some(m))
    Option(of) -> Option(min(of, m))
    _ -> type_
  }
}

pub fn max(type_: OpenAPIType, max m: Spec) -> OpenAPIType {
  case type_ {
    Number(..) -> Number(..type_, max: Some(m))
    Option(of) -> Option(max(of, m))
    _ -> type_
  }
}

pub fn title(type_: OpenAPIType, title t: String) -> OpenAPIType {
  case type_ {
    String(..) -> String(..type_, title: Some(t))
    Integer(..) -> Integer(..type_, title: Some(t))
    Number(..) -> Number(..type_, title: Some(t))
    Boolean(..) -> Boolean(..type_, title: Some(t))
    Array(..) -> Array(..type_, title: Some(t))
    Object(..) -> Object(..type_, title: Some(t))
    Null -> Null
    Option(of) -> Option(title(of, t))
    OneOf(values) -> OneOf(values: list.map(values, title(_, t)))
  }
}

/// A string type with no specific format, default, pattern, examples, or enum.
pub fn string() -> OpenAPIType {
  String(
    format: None,
    default: None,
    pattern: None,
    examples: [],
    enum: [],
    title: None,
  )
}

/// A string type with a predefined set of allowed values (enum).
pub fn string_enum(options: List(String)) -> OpenAPIType {
  String(
    format: None,
    default: None,
    pattern: None,
    examples: [],
    enum: options,
    title: None,
  )
}

/// An integer type with no specific format, default, or examples.
pub fn integer() -> OpenAPIType {
  Integer(format: None, default: None, examples: [], title: None)
}

/// A number type with no specific format, default, or examples.
pub fn number() -> OpenAPIType {
  Number(
    format: None,
    default: None,
    examples: [],
    min: None,
    max: None,
    title: None,
  )
}

/// A boolean type with no specific format, default, or examples.
pub fn boolean() -> OpenAPIType {
  Boolean(format: None, default: None, examples: [], title: None)
}

/// An array type with no specific format, default, items, or examples.
pub fn untyped_array() -> OpenAPIType {
  Array(format: None, default: None, items: None, examples: [], title: None)
}

/// An array type with a specified item type and no specific format, default, or examples.
pub fn array(items: OpenAPIType) -> OpenAPIType {
  Array(
    format: None,
    default: None,
    items: Some(items),
    examples: [],
    title: None,
  )
}

/// An object type with the given properties and no specific format, default, or examples.
pub fn object(properties: List(ObjectProperty)) -> OpenAPIType {
  Object(
    format: None,
    default: None,
    properties: properties,
    examples: [],
    title: None,
  )
}

/// An optional type wrapping another OpenAPI type.
pub fn option(of: OpenAPIType) -> OpenAPIType {
  Option(of: of)
}

/// A oneOf type representing a union of several possible OpenAPI types.
pub fn one_of(values: List(OpenAPIType)) -> OpenAPIType {
  OneOf(values: values)
}

/// Convert the OpenAPI type to a list of schema type strings.
fn to_schema_type(type_: OpenAPIType) -> List(String) {
  case type_ {
    String(..) -> ["string"]
    Integer(..) -> ["integer"]
    Number(..) -> ["number"]
    Boolean(..) -> ["boolean"]
    Array(..) -> ["array"]
    Object(..) -> ["object"]
    Null -> ["null"]
    Option(of:) -> ["null", ..to_schema_type(of)]
    OneOf(..) -> []
  }
}

/// Get the format of the OpenAPI type, if any.
fn format_of(type_: OpenAPIType) -> Option(String) {
  case type_ {
    String(format:, ..) -> format
    Integer(format:, ..) -> format
    Number(format:, ..) -> format
    Boolean(format:, ..) -> format
    Array(format:, ..) -> format
    Object(format:, ..) -> format
    Null -> None
    Option(of:) -> format_of(of)
    OneOf(..) -> None
  }
}

/// Get the default value of the OpenAPI type, if any.
fn default_of(type_: OpenAPIType) -> Option(Spec) {
  case type_ {
    String(default:, ..) -> default
    Integer(default:, ..) -> default
    Number(default:, ..) -> default
    Boolean(default:, ..) -> default
    Array(default:, ..) -> default
    Object(default:, ..) -> default
    Null -> None
    Option(of:) -> default_of(of)
    OneOf(..) -> None
  }
}

/// Get the examples of the OpenAPI type, if any.
fn examples_of(type_: OpenAPIType) -> List(Spec) {
  case type_ {
    String(examples:, ..) -> examples
    Integer(examples:, ..) -> examples
    Number(examples:, ..) -> examples
    Boolean(examples:, ..) -> examples
    Array(examples:, ..) -> examples
    Object(examples:, ..) -> examples
    Null -> []
    Option(of:) -> examples_of(of)
    OneOf(..) -> []
  }
}

/// Get the title of the OpenAPI type, if any.
fn title_of(type_: OpenAPIType) -> Option(String) {
  case type_ {
    String(title:, ..) -> title
    Integer(title:, ..) -> title
    Number(title:, ..) -> title
    Boolean(title:, ..) -> title
    Array(title:, ..) -> title
    Object(title:, ..) -> title
    Null -> None
    Option(of:) -> title_of(of)
    OneOf(..) -> None
  }
}

pub fn to_schema(type_: OpenAPIType) -> openapi.Schema {
  case type_ {
    OneOf(values) -> openapi.schema.one_of(list.map(values, to_schema))
    _ ->
      openapi.Schema(
        type_: to_schema_type(type_),
        format: format_of(type_),
        default: default_of(type_),
        pattern: case type_ {
          String(pattern:, ..) -> pattern
          _ -> None
        },
        items: case type_ {
          Array(items:, ..) -> option.map(items, to_schema)
          _ -> None
        },
        properties: case type_ {
          Object(properties:, ..) ->
            properties
            |> list.map(fn(entry) { #(entry.name, to_schema(entry.type_)) })
          _ -> []
        },
        enum: case type_ {
          String(enum:, ..) -> enum
          _ -> []
        },
        required: case type_ {
          Object(properties:, ..) ->
            properties
            |> list.filter(fn(entry) { entry.required })
            |> list.map(fn(entry) { entry.name })
          _ -> []
        },
        examples: examples_of(type_),
        minimum: case type_ {
          Number(min:, ..) -> min
          _ -> None
        },
        maximum: case type_ {
          Number(max:, ..) -> max
          _ -> None
        },
        title: title_of(type_),
      )
  }
}
