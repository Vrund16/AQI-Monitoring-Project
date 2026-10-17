function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  if (err.type === "entity.parse.failed") {
    return res.status(400).json({
      status: "error",
      message: "Invalid JSON request body."
    });
  }

  console.error(err.message);

  return res.status(500).json({
    status: "error",
    message: "Internal server error."
  });
}

module.exports = errorHandler;
