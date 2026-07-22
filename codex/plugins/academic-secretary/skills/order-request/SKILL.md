---
name: order-request
description: Process a quotation PDF into the academic budget database, render the purchase-request workbook, archive the quotation, and generate a verified request PDF. Use for purchase orders, quotations, budget checks, or university purchase-request documents.
---

# Order request

Read [the shared contract](../../references/secretary-contract.md) and `~/work/projects/admin/CLAUDE.md` before acting. The database and scripts in that repository are authoritative.

## Safety boundary

- Support preview-only and dry-run requests without changing the database, workbook, or PDFs.
- Treat `data/budget.db` as the source of truth and the workbook as a rendering layer.
- Run `git status` and fetch before edits. If the admin repository is dirty, identify whether the database already changed and stop for direction rather than pulling over it.
- Obtain explicit approval of vendor, items, tax treatment, fund, section, purpose, dates, and total before recording.
- Execute `record-order` at most once. Preserve the returned `orders.id`; never retry that step after a later rendering failure.

## Workflow

1. Identify the supplied quotation PDF. If omitted, inspect the newest PDF in `~/Downloads` and state which file was chosen.
2. Use the installed PDF workflow to extract vendor, item names, specifications, quantities, units, printed unit prices, subtotal, tax, and total. Do not independently convert printed tax-inclusive and tax-exclusive unit prices.
3. Ask once for missing fund, section, purpose, delivery date, and optional business name.
4. Show a complete preview table. Verify whether item-level tax-inclusive pricing or subtotal-level external tax exactly reproduces the quotation total. If neither matches, correct extraction instead of choosing the closer result.
5. List candidate plans with `budget_store.py list-plans`; ask which plan to consume. Check remaining budget with `remaining`, adding a consumed plan amount back before subtracting the order total. Handle fund splits only through the documented `--splits-json` mechanism and explicit approval.
6. After approval, run `record-order` once and retain the ID.
7. Render the workbook using `render_request_xlsx.py --order-id {id}`. This step may be retried with the same ID.
8. Copy, never move, the quotation into the fiscal-year submission folder. Generate the request PDF with the documented Excel route, falling back to `render_request_pdf.py` when needed.
9. Verify the final PDF’s page count, size, layout, amounts, vendor, dates, and Japanese text using the installed PDF workflow.
10. Report every produced path and the expected remaining balance. Ask whether to commit `data/budget.db`; never commit automatically.

If a post-recording step fails, resume from the stored order ID. Delete an order only with explicit user approval and the documented forced delete command.
