import { useMemo, useState } from "react";
import "./Table.css";
import Button from "./Button";

const PAGE_SIZES = [5, 10, 20, 50];

const SearchIcon = () => (
  <svg
    aria-hidden="true"
    className="table-icon"
    fill="none"
    viewBox="0 0 24 24"
  >
    <circle cx="11" cy="11" r="7" stroke="currentColor" strokeWidth="1.8" />
    <path
      d="m16.5 16.5 4 4"
      stroke="currentColor"
      strokeLinecap="round"
      strokeWidth="1.8"
    />
  </svg>
);
const DownloadIcon = () => (
  <svg
    aria-hidden="true"
    className="table-icon"
    fill="none"
    viewBox="0 0 24 24"
  >
    <path
      d="M12 3v11m0 0 4-4m-4 4-4-4M5 18v2h14v-2"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="1.8"
    />
  </svg>
);
const Chevron = ({ right }) => (
  <svg
    aria-hidden="true"
    className="table-icon"
    fill="none"
    viewBox="0 0 24 24"
  >
    <path
      d={right ? "m9 6 6 6-6 6" : "m15 18-6-6 6-6"}
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
    />
  </svg>
);

function Table({ objetsProps, title = "Données", pageSizeInitial = 10 }) {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(pageSizeInitial);
  const [selected, setSelected] = useState(new Set());
  const rows = useMemo(
    () => (Array.isArray(objetsProps) ? objetsProps : []),
    [objetsProps],
  );
  const columns = useMemo(
    () => Array.from(new Set(rows.flatMap((row) => Object.keys(row)))),
    [rows],
  );
  const filteredRows = useMemo(() => {
    const query = search.trim().toLocaleLowerCase("fr");
    return query
      ? rows.filter((row) =>
          columns.some((column) =>
            displayValue(row[column]).toLocaleLowerCase("fr").includes(query),
          ),
        )
      : rows;
  }, [columns, rows, search]);
  const pageCount = Math.max(1, Math.ceil(filteredRows.length / pageSize));
  const currentPage = Math.min(page, pageCount);
  const start = (currentPage - 1) * pageSize;
  const visibleRows = filteredRows.slice(start, start + pageSize);
  const visibleKeys = visibleRows.map((row, index) =>
    rowKey(row, start + index),
  );
  const allSelected =
    visibleKeys.length > 0 && visibleKeys.every((key) => selected.has(key));

  const toggleAll = () =>
    setSelected((previous) => {
      const next = new Set(previous);
      visibleKeys.forEach((key) =>
        allSelected ? next.delete(key) : next.add(key),
      );
      return next;
    });
  const toggleRow = (key) =>
    setSelected((previous) => {
      const next = new Set(previous);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });
  const exportCsv = () => {
    const values = [
      columns,
      ...filteredRows.map((row) =>
        columns.map((column) => displayValue(row[column])),
      ),
    ];
    const csv = values.map((row) => row.map(csvCell).join(",")).join("\n");
    const url = URL.createObjectURL(
      new Blob([`\uFEFF${csv}`], { type: "text/csv;charset=utf-8" }),
    );
    const link = document.createElement("a");
    link.href = url;
    link.download = `${title.toLowerCase().replace(/[^a-z0-9]+/gi, "-") || "donnees"}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  return (
    <section className="data-table-card">
      <header className="data-table-toolbar">
        <div>
          <h2>{title}</h2>
          <p>
            {filteredRows.length} résultat{filteredRows.length > 1 ? "s" : ""}
          </p>
        </div>
        <div className="data-table-actions">
          <label className="data-table-search">
            <SearchIcon />
            <span className="sr-only">Rechercher</span>
            <input
              onChange={(event) => {
                setSearch(event.target.value);
                setPage(1);
              }}
              placeholder="Rechercher..."
              type="search"
              value={search}
            />
          </label>
          <Button
            className="table-button"
            disabled={!filteredRows.length}
            icon={<DownloadIcon />}
            onClick={exportCsv}
            type="button"
            variant="secondary"
          >
            Exporter
          </Button>
        </div>
      </header>

      {!rows.length ? (
        <div className="data-table-empty">
          <span>—</span>
          <strong>Aucune donnée disponible</strong>
          <p>Les données apparaîtront ici dès qu’elles seront disponibles.</p>
        </div>
      ) : (
        <>
          <div className="data-table-scroll">
            <table className="generic-table">
              <thead>
                <tr>
                  <th className="checkbox-column">
                    <input
                      aria-label="Sélectionner les lignes visibles"
                      checked={allSelected}
                      onChange={toggleAll}
                      type="checkbox"
                    />
                  </th>
                  {columns.map((column) => (
                    <th key={column}>{formatLabel(column)}</th>
                  ))}
                  <th aria-label="Actions" className="actions-column" />
                </tr>
              </thead>
              <tbody>
                {visibleRows.map((row, index) => {
                  const key = rowKey(row, start + index);
                  return (
                    <tr
                      className={selected.has(key) ? "is-selected" : ""}
                      key={key}
                    >
                      <td className="checkbox-column">
                        <input
                          aria-label={`Sélectionner la ligne ${start + index + 1}`}
                          checked={selected.has(key)}
                          onChange={() => toggleRow(key)}
                          type="checkbox"
                        />
                      </td>
                      {columns.map((column) => (
                        <td key={column}>{renderValue(row[column], column)}</td>
                      ))}
                      <td className="actions-column">
                        <button
                          aria-label="Plus d’actions"
                          className="more-button"
                          type="button"
                        >
                          •••
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          {!filteredRows.length ? (
            <div className="data-table-no-result">
              Aucun résultat pour « {search} »
            </div>
          ) : (
            <footer className="data-table-footer">
              <p>
                Affichage de {start + 1} à{" "}
                {Math.min(start + pageSize, filteredRows.length)} sur{" "}
                {filteredRows.length}
              </p>
              <div className="pagination-controls">
                <label>
                  Lignes par page
                  <select
                    value={pageSize}
                    onChange={(event) => {
                      setPageSize(Number(event.target.value));
                      setPage(1);
                    }}
                  >
                    {PAGE_SIZES.map((size) => (
                      <option key={size} value={size}>
                        {size}
                      </option>
                    ))}
                  </select>
                </label>
                <button
                  aria-label="Page précédente"
                  disabled={currentPage === 1}
                  onClick={() => setPage(currentPage - 1)}
                  type="button"
                >
                  <Chevron />
                </button>
                <span>
                  {currentPage} / {pageCount}
                </span>
                <button
                  aria-label="Page suivante"
                  disabled={currentPage === pageCount}
                  onClick={() => setPage(currentPage + 1)}
                  type="button"
                >
                  <Chevron right />
                </button>
              </div>
            </footer>
          )}
        </>
      )}
    </section>
  );
}

function rowKey(row, index) {
  return String(row.id ?? row.uuid ?? row.code ?? `row-${index}`);
}
function formatLabel(label) {
  return String(label)
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .replace(/[_-]+/g, " ")
    .replace(/^./, (letter) => letter.toUpperCase());
}
function displayValue(value) {
  if (value === null || value === undefined || value === "") return "—";
  if (typeof value === "boolean") return value ? "Oui" : "Non";
  if (typeof value === "object")
    return Array.isArray(value)
      ? value.map(displayValue).join(", ")
      : (value.nom ?? value.name ?? value.libelle ?? JSON.stringify(value));
  return String(value);
}
function renderValue(value, column) {
  const text = displayValue(value);
  const normalized = text.toLocaleLowerCase("fr");
  const isStatus = /(statut|status|etat|état|active|actif)/i.test(column);
  if (
    isStatus ||
    [
      "oui",
      "non",
      "actif",
      "inactive",
      "terminé",
      "annulé",
      "en attente",
    ].includes(normalized)
  ) {
    const tone = /annul|refus|erreur|inactif|inactive|non/.test(normalized)
      ? "danger"
      : /attente|pending|cours|review/.test(normalized)
        ? "warning"
        : "success";
    return <span className={`status-badge status-${tone}`}>{text}</span>;
  }
  return (
    <span className="cell-value" title={text}>
      {text}
    </span>
  );
}
function csvCell(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}

export default Table;
