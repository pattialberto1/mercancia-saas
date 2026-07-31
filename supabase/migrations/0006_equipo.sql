-- ============================================================
-- Mercancía SaaS · 0006: gestión del equipo desde la app
--
-- Dos cosas que hasta ahora obligaban a entrar al panel de Supabase:
--   1. Ver quién es quién en el negocio (la tabla no guardaba el usuario).
--   2. Cambiarle la contraseña a un operador que la olvidó.
--
-- Cómo se corre: Supabase → SQL Editor → New query → pegar todo → Run.
-- Es seguro correrlo aunque ya esté aplicado.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Guardar el usuario en la membresía
-- ------------------------------------------------------------
-- El nombre de usuario vivía solo dentro de auth.users, que la app no puede
-- leer (y con razón). Guardándolo aquí, el dueño ve a su equipo por nombre
-- sin necesidad de permisos de administrador.
alter table memberships add column if not exists usuario text;

-- rellenar las membresías que ya existen
update memberships m
set usuario = coalesce(
  u.raw_user_meta_data ->> 'usuario',
  case when split_part(u.email, '@', 2) = 'mercancia.local'
       then split_part(u.email, '@', 1) else u.email end)
from auth.users u
where u.id = m.user_id and m.usuario is null;

-- y que las nuevas lo traigan de fábrica
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_invite text;
  v_negocio text;
  v_usuario text;
begin
  v_invite := new.raw_user_meta_data ->> 'invite_code';
  v_negocio := new.raw_user_meta_data ->> 'nombre_negocio';
  -- los operadores entran con usuario; el dueño con su correo real
  v_usuario := coalesce(
    new.raw_user_meta_data ->> 'usuario',
    case when split_part(new.email, '@', 2) = 'mercancia.local'
         then split_part(new.email, '@', 1) else new.email end);

  if v_invite is not null then
    select id into v_tenant_id from tenants where invite_code = v_invite;
    if v_tenant_id is null then
      raise exception 'Código de invitación inválido';
    end if;
    insert into memberships (tenant_id, user_id, role, usuario)
      values (v_tenant_id, new.id, 'operador', v_usuario);

  elsif v_negocio is not null then
    insert into tenants default values returning id into v_tenant_id;
    insert into tenant_profile (tenant_id, nombre_negocio) values (v_tenant_id, v_negocio);
    insert into memberships (tenant_id, user_id, role, usuario)
      values (v_tenant_id, new.id, 'dueno', v_usuario);

  else
    raise exception 'Falta nombre_negocio o invite_code al registrarse';
  end if;

  return new;
end;
$$;

-- ------------------------------------------------------------
-- 2. Que el dueño pueda resetear la clave de un operador
-- ------------------------------------------------------------
-- Cambiarle la contraseña a otra persona normalmente exige la llave de
-- administrador del proyecto, y esa llave NO puede estar dentro de la app
-- (cualquiera la sacaría del navegador y tomaría control de todos los
-- negocios). Por eso se hace aquí dentro: la función corre con permisos
-- elevados pero comprueba ella misma, en cada llamada, que quien la invoca
-- sea el dueño del MISMO negocio y que el destinatario sea un operador de
-- ese negocio. Fuera de esas dos condiciones no hace nada.
create or replace function resetear_clave_operador(p_user_id uuid, p_nueva text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_tenant_id uuid;
begin
  if p_nueva is null or length(p_nueva) < 6 then
    raise exception 'La contraseña debe tener al menos 6 caracteres';
  end if;

  -- ¿a qué negocio pertenece el operador, y es realmente un operador?
  select tenant_id into v_tenant_id
  from memberships
  where user_id = p_user_id and role = 'operador';

  if v_tenant_id is null then
    raise exception 'Esa persona no es un operador de ningún negocio';
  end if;

  -- ¿quien llama es el dueño de ESE negocio?
  if not exists (
    select 1 from memberships
    where tenant_id = v_tenant_id and user_id = auth.uid() and role = 'dueno'
  ) then
    raise exception 'Solo el dueño del negocio puede cambiar la contraseña de su equipo';
  end if;

  update auth.users
  set encrypted_password = extensions.crypt(p_nueva, extensions.gen_salt('bf')),
      updated_at = now()
  where id = p_user_id;

  -- cerrarle la sesión en los teléfonos donde hubiera quedado abierta, para
  -- que la clave nueva sea la única forma de volver a entrar
  delete from auth.refresh_tokens where user_id::uuid = p_user_id;
end;
$$;

-- nadie sin sesión iniciada puede ni intentarlo
revoke all on function resetear_clave_operador(uuid, text) from public, anon;
grant execute on function resetear_clave_operador(uuid, text) to authenticated;

-- ------------------------------------------------------------
-- 3. Comprobación
-- ------------------------------------------------------------
do $$
declare faltan text := '';
begin
  if not exists (select 1 from information_schema.columns
                 where table_name = 'memberships' and column_name = 'usuario') then
    faltan := faltan || 'columna usuario, ';
  end if;
  if not exists (select 1 from pg_proc where proname = 'resetear_clave_operador') then
    faltan := faltan || 'función resetear_clave_operador, ';
  end if;
  if faltan = '' then
    raise notice 'Todo al día: el dueño ya puede ver su equipo y resetear contraseñas desde la app.';
  else
    raise exception 'Todavía falta: %', rtrim(faltan, ', ');
  end if;
end $$;
