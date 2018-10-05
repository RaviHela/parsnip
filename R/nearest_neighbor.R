# TODO) If implementing `class::knn()`, mention that it does not have
# the distance param because it uses Euclidean distance. And no `weight_func`
# param.

#' General Interface for K-Nearest Neighbor Models
#'
#' `nearest_neighbor()` is a way to generate a _specification_ of a model
#'  before fitting and allows the model to be created using
#'  different packages in R. The main arguments for the
#'  model are:
#' \itemize{
#'   \item \code{neighbors}: The number of neighbors considered at
#'   each prediction.
#'   \item \code{weight_func}: The type of kernel function that weights the
#'   distances between samples.
#'   \item \code{dist_power}: The parameter used when calculating the Minkowski
#'   distance. This corresponds to the Manhattan distance with `dist_power = 1`
#'   and the Euclidean distance with `dist_power = 2`.
#' }
#' These arguments are converted to their specific names at the
#'  time that the model is fit. Other options and argument can be
#'  set using the `others` argument. If left to their defaults
#'  here (`NULL`), the values are taken from the underlying model
#'  functions. If parameters need to be modified, `update()` can be used
#'  in lieu of recreating the object from scratch.
#'
#' @param mode A single character string for the type of model.
#' Possible values for this model are `"unknown"`, `"regression"`, or
#' `"classification"`.
#'
#' @param neighbors A single integer for the number of neighbors
#' to consider (often called `k`).
#'
#' @param weight_func A *single* character for the type of kernel function used
#' to weight distances between samples. Valid choices are: `"rectangular"`,
#' `"triangular"`, `"epanechnikov"`, `"biweight"`, `"triweight"`,
#' `"cos"`, `"inv"`, `"gaussian"`, `"rank"`, or `"optimal"`.
#'
#' @param dist_power A single number for the parameter used in
#' calculating Minkowski distance.
#'
#' @param others A named list of arguments to be used by the
#'  underlying models (e.g., `kknn::train.kknn`). These are not evaluated
#'  until the model is fit and will be substituted into the model
#'  fit expression.
#'
#' @param ... Used for S3 method consistency. Any arguments passed to
#'  the ellipses will result in an error. Use `others` instead.
#'
#' @details
#' The model can be created using the `fit()` function using the
#'  following _engines_:
#' \itemize{
#' \item \pkg{R}:  `"kknn"`
#' }
#'
#' Engines may have pre-set default arguments when executing the
#'  model fit call. These can be changed by using the `others`
#'  argument to pass in the preferred values. For this type of
#'  model, the template of the fit calls are:
#'
#' \pkg{kknn} (classification or regression)
#'
#' \Sexpr[results=rd]{parsnip:::show_fit(parsnip:::nearest_neighbor(), "kknn")}
#'
#' @note
#' For `kknn`, the underlying modeling function used is a restricted
#' version of `train.kknn()` and not `kknn()`. It is set up in this way so that
#' `parsnip` can utilize the underlying `predict.train.kknn` method to predict
#' on new data. This also means that a single value of that function's
#' `kernel` argument (a.k.a `weight_func` here) can be supplied
#'
#' @seealso [varying()], [fit()]
#'
#' @examples
#' nearest_neighbor()
#'
#' @export
nearest_neighbor <- function(mode = "unknown",
                             neighbors = NULL,
                             weight_func = NULL,
                             dist_power = NULL,
                             others = list(),
                             ...) {

  check_empty_ellipse(...)

  ## TODO: make a utility function here
  if (!(mode %in% nearest_neighbor_modes)) {
    stop("`mode` should be one of: ",
         paste0("'", nearest_neighbor_modes, "'", collapse = ", "),
         call. = FALSE)
  }

  if(is.numeric(neighbors) && !positive_int_scalar(neighbors)) {
    stop("`neighbors` must be a length 1 positive integer.", call. = FALSE)
  }

  if(is.character(weight_func) && length(weight_func) > 1) {
    stop("The length of `weight_func` must be 1.", call. = FALSE)
  }

  args <- list(
    neighbors = neighbors,
    weight_func = weight_func,
    dist_power = dist_power
  )

  no_value <- !vapply(others, is.null, logical(1))
  others <- others[no_value]

  # write a constructor function
  out <- list(args = args, others = others,
              mode = mode, method = NULL, engine = NULL)
  # TODO: make_classes has wrong order; go from specific to general
  class(out) <- make_classes("nearest_neighbor")
  out
}

#' @export
print.nearest_neighbor <- function(x, ...) {
  cat("K-Nearest Neighbor Model Specification (", x$mode, ")\n\n", sep = "")
  model_printer(x, ...)

  if(!is.null(x$method$fit$args)) {
    cat("Model fit template:\n")
    print(show_call(x))
  }
  invisible(x)
}

# ------------------------------------------------------------------------------

#' @export
update.nearest_neighbor <- function(object,
                                    neighbors = NULL,
                                    weight_func = NULL,
                                    dist_power = NULL,
                                    others = list(),
                                    fresh = FALSE,
                                    ...) {

  check_empty_ellipse(...)

  if(is.numeric(neighbors) && !positive_int_scalar(neighbors)) {
    stop("`neighbors` must be a length 1 positive integer.", call. = FALSE)
  }

  if(is.character(weight_func) && length(weight_func) > 1) {
    stop("The length of `weight_func` must be 1.", call. = FALSE)
  }

  args <- list(
    neighbors = neighbors,
    weight_func = weight_func,
    dist_power = dist_power
  )

  if (fresh) {
    object$args <- args
  } else {
    null_args <- map_lgl(args, null_value)
    if (any(null_args))
      args <- args[!null_args]
    if (length(args) > 0)
      object$args[names(args)] <- args
  }

  if (length(others) > 0) {
    if (fresh)
      object$others <- others
    else
      object$others[names(others)] <- others
  }

  object
}


positive_int_scalar <- function(x) {
  (length(x) == 1) && (x > 0) && (x %% 1 == 0)
}