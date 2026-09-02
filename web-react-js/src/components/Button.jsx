import "./Button.css";

const classesParVariante = {
  secondary: "btn-modern",
  primary: "btn-modern btn-primary",
  assign: "btn-assign",
  validate: "btn-validate",
  danger: "btn-modern btn-danger",
};

function Button({
  children,
  variant = "primary",
  loading = false,
  fullWidth = false,
  icon = null,
  iconPosition = "start",
  className = "",
  disabled = false,
  type = "button",
  ...buttonProps
}) {
  const classes = [
    classesParVariante[variant] ?? classesParVariante.primary,
    fullWidth ? "btn-full-width" : "",
    loading ? "btn-loading" : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button
      {...buttonProps}
      type={type}
      className={classes}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
    >
      {loading && <span className="btn-spinner" aria-hidden="true" />}
      {!loading && icon && iconPosition === "start" && icon}
      <span>{children}</span>
      {!loading && icon && iconPosition === "end" && icon}
    </button>
  );
}

export default Button;
