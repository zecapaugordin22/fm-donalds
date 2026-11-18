-- FM Donalds: catalog and promotional cards
-- Run this file in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  image_url text,
  image_alt text not null default '',
  category text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  label text not null default '',
  title text not null,
  description text not null default '',
  position integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promotions_valid_period check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create index if not exists promotions_public_order_idx
  on public.promotions (position, starts_at, ends_at)
  where active = true;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

drop trigger if exists promotions_set_updated_at on public.promotions;
create trigger promotions_set_updated_at
  before update on public.promotions
  for each row execute function public.set_updated_at();

alter table public.products enable row level security;
alter table public.promotions enable row level security;

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products"
  on public.products for select to anon, authenticated
  using (active = true);

drop policy if exists "Public can read active promotions" on public.promotions;
create policy "Public can read active promotions"
  on public.promotions for select to anon, authenticated
  using (
    active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now())
  );

-- Seed the three cards currently displayed in index.html.
insert into public.products (slug, name, description, image_url, image_alt, category)
values
  ('hamburguer-da-casa', 'Um mordidão de felicidade', 'Seu hambúrguer favorito, preparado na hora para deixar o dia mais gostoso.', 'ham.jpg', 'Hambúrguer suculento com queijo, alface e tomate', 'Hambúrgueres'),
  ('batata-frita', 'Batata quentinha? Sempre!', 'Dourada por fora, macia por dentro e perfeita para dividir — ou não.', 'batata.jpg', 'Porção dourada de batatas fritas', 'Acompanhamentos'),
  ('sobremesa-gelada', 'Final feliz em cada colherada', 'Uma pausa geladinha e cremosa para transformar qualquer dia.', 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=900&q=80', 'Sorvete servido com calda de chocolate', 'Sobremesas')
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  image_url = excluded.image_url,
  image_alt = excluded.image_alt,
  category = excluded.category;

insert into public.promotions (product_id, label, title, description, position)
select p.id, seed.label, seed.title, seed.description, seed.position
from (values
  ('hamburguer-da-casa', 'Clássico de respeito', 'Um mordidão de felicidade', 'Seu hambúrguer favorito, preparado na hora para deixar o dia mais gostoso.', 1),
  ('batata-frita', 'Parceira de todo lanche', 'Batata quentinha? Sempre!', 'Dourada por fora, macia por dentro e perfeita para dividir — ou não.', 2),
  ('sobremesa-gelada', 'Um docinho faz bem', 'Final feliz em cada colherada', 'Uma pausa geladinha e cremosa para transformar qualquer dia.', 3)
) as seed(slug, label, title, description, position)
join public.products p on p.slug = seed.slug
where not exists (
  select 1 from public.promotions existing
  where existing.product_id = p.id and existing.title = seed.title
);
