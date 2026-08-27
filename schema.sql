-- OPERACIÓN DUNKIRK · SHAKA CONCEJAL 2026-2031
-- Versión combinada: crea todo de una — equivalente a correr las 2 migraciones
-- (supabase/migrations/20260827000001_masters.sql y ..._electores.sql) juntas.
-- Ejecutar en Supabase: Panel del proyecto -> SQL Editor -> New query -> pegar y correr.
--
-- Si ya habías corrido una versión anterior de este archivo (con columnas
-- "master"/"telefono_master" de texto en electores), no uses este archivo:
-- corré en cambio supabase/migrations/20260827000003_upgrade_existing_electores.sql

create extension if not exists "pgcrypto";

-- ---------- MASTERS ----------
create table if not exists public.masters (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  telefono text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid()
);

alter table public.masters enable row level security;

create policy "Usuarios autenticados pueden leer masters"
  on public.masters for select to authenticated using (true);
create policy "Usuarios autenticados pueden insertar masters"
  on public.masters for insert to authenticated with check (true);
create policy "Usuarios autenticados pueden actualizar masters"
  on public.masters for update to authenticated using (true);
create policy "Usuarios autenticados pueden borrar masters"
  on public.masters for delete to authenticated using (true);

create index if not exists masters_nombre_idx on public.masters (nombre);

-- ---------- ELECTORES ----------
create table if not exists public.electores (
  id uuid primary key default gen_random_uuid(),
  master_id uuid references public.masters(id) on delete set null,
  elector text not null,
  telefono_elector text,
  voto text,                    -- "A favor" | "Indeciso" | "En contra" | "No define" (editable en el frontend)
  colegio_electoral text,
  movil_asignado text,
  chofer text,
  telefono_chofer text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid()
);

alter table public.electores enable row level security;

create policy "Usuarios autenticados pueden leer electores"
  on public.electores for select to authenticated using (true);
create policy "Usuarios autenticados pueden insertar electores"
  on public.electores for insert to authenticated with check (true);
create policy "Usuarios autenticados pueden actualizar electores"
  on public.electores for update to authenticated using (true);
create policy "Usuarios autenticados pueden borrar electores"
  on public.electores for delete to authenticated using (true);

create index if not exists electores_master_idx on public.electores (master_id);
create index if not exists electores_colegio_idx on public.electores (colegio_electoral);
create index if not exists electores_voto_idx on public.electores (voto);
