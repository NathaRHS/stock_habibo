import { useId } from "react";
import styles from "./QuantitySlider.module.css";

const GRADUATIONS = 25;

function QuantitySlider({ label, valeur, max, onChange, disabled = false }) {
  const id = useId();
  const nombre = Number(valeur);
  const borne = Math.min(Math.max(Number.isFinite(nombre) ? nombre : 1, 1), Math.max(max, 1));
  const ratio = max > 1 ? (borne - 1) / (max - 1) : 1;

  const clamp = (texte) => {
    const entier = Math.round(Number(texte));
    onChange(Number.isFinite(entier) ? Math.min(Math.max(entier, 1), Math.max(max, 1)) : 1);
  };

  return (
    <div className={`${styles.root} ${disabled ? styles.disabled : ""}`}>
      <label className={styles.label} htmlFor={id}>
        {label}
      </label>
      <div className={styles.controls}>
        <div className={styles.track}>
          <div className={styles.ticks} aria-hidden="true">
            {Array.from({ length: GRADUATIONS }, (_, index) => {
              const position = index / (GRADUATIONS - 1);
              return (
                <span
                  className={[
                    position <= ratio ? styles.filled : "",
                    index % 6 === 0 ? styles.major : "",
                  ].join(" ")}
                  key={index}
                />
              );
            })}
          </div>
          <input
            aria-label={`${label} (curseur)`}
            className={styles.range}
            disabled={disabled || max <= 1}
            max={Math.max(max, 1)}
            min={1}
            onChange={(event) => onChange(Number(event.target.value))}
            step={1}
            type="range"
            value={borne}
          />
        </div>
        <input
          className={styles.value}
          disabled={disabled}
          id={id}
          inputMode="numeric"
          max={Math.max(max, 1)}
          min={1}
          onBlur={(event) => clamp(event.target.value)}
          onChange={(event) => onChange(event.target.value)}
          type="number"
          value={valeur}
        />
      </div>
      <div className={styles.scale}>
        <span>1</span>
        <button
          disabled={disabled || borne === max}
          onClick={() => onChange(max)}
          type="button"
        >
          Max · {max}
        </button>
      </div>
    </div>
  );
}

export default QuantitySlider;
