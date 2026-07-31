-- ============================================================
-- Mercancía SaaS · 0005: ponerse al día (precio por kg + tasa BCV)
--
-- ¿Para qué es esto? Si tu proyecto de Supabase se creó antes de que
-- existiera el precio por kg en los despachos, a la tabla le faltan dos
-- campos y la app te dirá "no se pudo guardar el precio". Este archivo
-- deja la base al día de una sola vez.
--
-- Cómo se corre: Supabase → SQL Editor → New query → pegar todo → Run.
-- Es seguro correrlo aunque ya esté aplicado (no borra ni duplica nada);
-- reemplaza a las migraciones 0003 y 0004 si no las corriste.
-- ============================================================

-- 1. los dos campos que faltan (no hace nada si ya están)
alter table receptions add column if not exists precio_kg numeric(10,2);
alter table receptions add column if not exists tasa_bcv numeric(12,4);

-- No hace falta ninguna política de seguridad nueva: guardar el precio es
-- un update de receptions, que ya cubre la política existente
-- "editar mis recepciones o si soy dueno" (creado por mí, o soy dueño).

-- 2. la vista de reportes, con el total ya calculado en dólares y en
--    bolívares. El monto se calcula al vuelo a partir del peso neto, así
--    nunca queda desactualizado si después se corrige o se borra una pesada.
drop view if exists reception_summary;
create view reception_summary
with (security_invoker = true) as
select
  r.id as reception_id,
  r.tenant_id,
  r.product_id,
  p.nombre as producto,
  p.emoji,
  r.tipo,
  r.client_id,
  c.nombre as cliente,
  r.fecha,
  r.status,
  r.cestas_vacias,
  r.precio_kg,
  r.tasa_bcv,
  coalesce(sum(w.cestas), 0) as cestas,
  coalesce(sum(w.peso), 0) as peso_bruto,
  coalesce(sum(w.cestas), 0) * coalesce(p.tara_kg, 0) as tara_total,
  coalesce(sum(w.peso), 0) - coalesce(sum(w.cestas), 0) * coalesce(p.tara_kg, 0) as peso_neto,
  case when r.precio_kg is not null
    then round((coalesce(sum(w.peso), 0) - coalesce(sum(w.cestas), 0) * coalesce(p.tara_kg, 0)) * r.precio_kg, 2)
    else null end as monto,
  case when r.precio_kg is not null and r.tasa_bcv is not null
    then round((coalesce(sum(w.peso), 0) - coalesce(sum(w.cestas), 0) * coalesce(p.tara_kg, 0)) * r.precio_kg * r.tasa_bcv, 2)
    else null end as monto_bs
from receptions r
join products p on p.id = r.product_id
left join clients c on c.id = r.client_id
left join weighings w on w.reception_id = r.id
group by r.id, p.id, c.id;

-- 3. comprobación: si sale "todo al día", la app ya puede guardar precios.
do $$
declare faltan text;
begin
  select string_agg(x, ', ') into faltan from (
    select 'precio_kg' as x where not exists (
      select 1 from information_schema.columns
      where table_name = 'receptions' and column_name = 'precio_kg')
    union all
    select 'tasa_bcv' where not exists (
      select 1 from information_schema.columns
      where table_name = 'receptions' and column_name = 'tasa_bcv')
    union all
    select 'monto_bs en reception_summary' where not exists (
      select 1 from information_schema.columns
      where table_name = 'reception_summary' and column_name = 'monto_bs')
  ) t;
  if faltan is null then
    raise notice 'Todo al día: la app ya puede guardar el precio por kg y la tasa.';
  else
    raise exception 'Todavía falta: %', faltan;
  end if;
end $$;
