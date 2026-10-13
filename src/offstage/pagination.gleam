import gleam/dynamic
import gleam/http/request.{type Request}
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import offstage/dynamic/serialize

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          Pagination                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// Represents pagination parameters for API requests.
/// - `page` is the current page number (starting from 1).
/// - `per_page` is the number of items to return per page.
pub type Pagination {
  Pagination(page: Int, per_page: Int)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       After Pagination                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// Represents pagination parameter for API requests with a cursor pointing to the item after which 
/// to start pagination.
/// - `after` is the cursor pointing to the item after which to start pagination.
/// - `per_page` is the number of items to return per page.
pub type AfterPagination(a) {
  AfterPagination(after: a, per_page: Int)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Before Pagination                                       //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// Represents pagination parameter for API requests with a cursor pointing to the item before 
/// which to start pagination.
/// - `before` is the cursor pointing to the item before which to start pagination.
/// - `per_page` is the number of items to return per page.
pub type BeforePagination(a) {
  BeforePagination(before: a, per_page: Int)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Configuration                                         //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

/// The configuration of the pagination strategy for API requests.
/// - `result` is the type of pagination (one of `Pagination`, `AfterPagination(b)`, or 
/// `BeforePagination(b)`).
/// - `cursor` is the type of the cursor for after and before pagination (Nil for Pagination).
/// - `request` is the type of the request.
pub type PaginationConfig(result, cursor, request) {
  SimplePaginationConfig(
    default_page: Int,
    default_per_page: Int,
    max_per_page: Int,
    parser: fn(PaginationConfig(result, cursor, request), Request(request)) ->
      result,
  )
  AfterPaginationConfig(
    default_after: cursor,
    after_serializer: serialize.Serializer(cursor),
    is_json: Bool,
    default_per_page: Int,
    max_per_page: Int,
    parser: fn(PaginationConfig(result, cursor, request), Request(request)) ->
      result,
  )
  BeforePaginationConfig(
    default_before: cursor,
    before_serializer: serialize.Serializer(cursor),
    is_json: Bool,
    default_per_page: Int,
    max_per_page: Int,
    parser: fn(PaginationConfig(result, cursor, request), Request(request)) ->
      result,
  )
}

/// Create a simple pagination configuration with default values.
/// - `default_page` set to 1
/// - `default_per_page` set to 10
/// - `max_per_page` set to 100
pub fn simple() -> PaginationConfig(Pagination, Nil, c) {
  SimplePaginationConfig(
    default_page: 1,
    default_per_page: 10,
    max_per_page: 100,
    parser: fn(self, request) {
      let assert SimplePaginationConfig(
        default_per_page:,
        default_page:,
        max_per_page:,
        ..,
      ) = self
      parse_simple(default_page:, default_per_page:, max_per_page:, request:)
    },
  )
}

/// Create an after pagination configuration with default values.
/// - `default_after` set to the provided default value
/// - `after_serializer` set to the provided serializer
/// - `is_json` set to False
/// - `default_per_page` set to 10
/// - `max_per_page` set to 100
pub fn after(
  default default: b,
  serializer serializer: serialize.Serializer(b),
) -> PaginationConfig(AfterPagination(b), b, c) {
  AfterPaginationConfig(
    default_after: default,
    after_serializer: serializer,
    is_json: False,
    default_per_page: 10,
    max_per_page: 100,
    parser: fn(self, request) {
      let assert AfterPaginationConfig(
        default_after:,
        after_serializer:,
        is_json:,
        default_per_page:,
        max_per_page:,
        ..,
      ) = self
      parse_with_cursor(
        is_json:,
        default_cursor: default_after,
        cursor_serializer: after_serializer,
        default_per_page:,
        max_per_page:,
        request:,
        cursor: "after",
        finish: fn(after, per_page) { AfterPagination(after:, per_page:) },
      )
    },
  )
}

/// Create a before pagination configuration with default values.
/// - `default_before` set to the provided default value
/// - `before_serializer` set to the provided serializer
/// - `is_json` set to False
/// - `default_per_page` set to 10
/// - `max_per_page` set to 100
pub fn before(
  default default: b,
  serializer serializer: serialize.Serializer(b),
) -> PaginationConfig(BeforePagination(b), b, c) {
  BeforePaginationConfig(
    default_before: default,
    before_serializer: serializer,
    is_json: False,
    default_per_page: 10,
    max_per_page: 100,
    parser: fn(self, request) {
      let assert BeforePaginationConfig(
        default_before:,
        before_serializer:,
        is_json:,
        default_per_page:,
        max_per_page:,
        ..,
      ) = self
      parse_with_cursor(
        is_json:,
        default_cursor: default_before,
        cursor_serializer: before_serializer,
        default_per_page:,
        max_per_page:,
        request:,
        cursor: "before",
        finish: fn(before, per_page) { BeforePagination(before:, per_page:) },
      )
    },
  )
}

/// Set the `is_json` flag to True (if supported).
/// Supported by `AfterPaginationConfig` and `BeforePaginationConfig`.
pub fn as_json(config: PaginationConfig(a, b, c)) -> PaginationConfig(a, b, c) {
  case config {
    SimplePaginationConfig(..) -> config
    AfterPaginationConfig(..) -> AfterPaginationConfig(..config, is_json: True)
    BeforePaginationConfig(..) ->
      BeforePaginationConfig(..config, is_json: True)
  }
}

/// Set the `default_per_page` value.
pub fn set_default_per_page(
  config: PaginationConfig(a, b, c),
  default_per_page: Int,
) -> PaginationConfig(a, b, c) {
  case config {
    SimplePaginationConfig(..) ->
      SimplePaginationConfig(..config, default_per_page: default_per_page)
    AfterPaginationConfig(..) ->
      AfterPaginationConfig(..config, default_per_page: default_per_page)
    BeforePaginationConfig(..) ->
      BeforePaginationConfig(..config, default_per_page: default_per_page)
  }
}

/// Set the `max_per_page` value.
pub fn set_max_per_page(
  config: PaginationConfig(a, b, c),
  max_per_page: Int,
) -> PaginationConfig(a, b, c) {
  case config {
    SimplePaginationConfig(..) ->
      SimplePaginationConfig(..config, max_per_page: max_per_page)
    AfterPaginationConfig(..) ->
      AfterPaginationConfig(..config, max_per_page: max_per_page)
    BeforePaginationConfig(..) ->
      BeforePaginationConfig(..config, max_per_page: max_per_page)
  }
}

/// Set the `default_page` value (if supported). 
/// Supported by `SimplePaginationConfig`.
pub fn set_default_page(
  config: PaginationConfig(a, b, c),
  default_page: Int,
) -> PaginationConfig(a, b, c) {
  case config {
    SimplePaginationConfig(..) ->
      SimplePaginationConfig(..config, default_page: default_page)
    AfterPaginationConfig(..) -> config
    BeforePaginationConfig(..) -> config
  }
}

/// The parse function for simple pagination.
fn parse_simple(
  default_page default_page: Int,
  default_per_page default_per_page: Int,
  max_per_page max_per_page: Int,
  request request: Request(c),
) -> Pagination {
  let query = request.get_query(request) |> result.unwrap([])

  let page =
    list.key_find(query, "page")
    |> result.map(fn(s) { int.parse(s) })
    |> result.flatten()
    |> result.unwrap(default_page)
    |> int.max(1)

  let per_page =
    list.key_find(query, "per_page")
    |> result.map(fn(s) { int.parse(s) })
    |> result.flatten()
    |> result.unwrap(default_per_page)
    |> int.clamp(1, max_per_page)

  Pagination(page: page, per_page: per_page)
}

/// The parse function for cursor-based pagination.
fn parse_with_cursor(
  is_json is_json: Bool,
  default_cursor default_cursor: a,
  cursor_serializer cursor_serializer: serialize.Serializer(a),
  default_per_page default_per_page: Int,
  max_per_page max_per_page: Int,
  request request: Request(c),
  cursor cursor: String,
  finish finish: fn(a, Int) -> b,
) -> b {
  let query = request.get_query(request) |> result.unwrap([])

  let after =
    list.key_find(query, cursor)
    |> result.map(fn(s) {
      case is_json {
        True ->
          json.parse(s, cursor_serializer.decoder) |> result.replace_error(Nil)
        False ->
          serialize.decode(dynamic.string(s), cursor_serializer)
          |> result.replace_error(Nil)
      }
    })
    |> result.flatten()
    |> result.unwrap(default_cursor)

  let per_page =
    list.key_find(query, "per_page")
    |> result.map(fn(s) { int.parse(s) })
    |> result.flatten()
    |> result.unwrap(default_per_page)
    |> int.clamp(1, max_per_page)

  finish(after, per_page)
}

/// Retrieve the pagination parameters from the request based on the configuration.
pub fn parse(config: PaginationConfig(a, b, c), request: Request(c)) -> a {
  case config {
    SimplePaginationConfig(parser:, ..) -> parser(config, request)
    AfterPaginationConfig(parser:, ..) -> parser(config, request)
    BeforePaginationConfig(parser:, ..) -> parser(config, request)
  }
}
