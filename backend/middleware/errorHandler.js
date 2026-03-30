const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  const status = err.status || 500;
  res.status(status).json({ msg: err.message || 'Internal server error' });
};

export default errorHandler;
