# Peya Backoffice Catalogo

Base inicial del panel de administracion para gestionar productos y categorias.

## Stack

- Next.js App Router + TypeScript
- Tailwind CSS
- Prisma ORM + PostgreSQL
- Autenticacion con JWT en cookie segura

## Inicio rapido

1. Copiar variables de entorno:

```bash
cp .env.example .env
```

2. Instalar dependencias:

```bash
npm install
```

3. Generar cliente Prisma y crear migracion inicial:

```bash
npx prisma generate
npx prisma migrate dev --name init
```

4. Ejecutar en desarrollo:

```bash
npm run dev
```

## Endpoints API

- `GET /api/products`
- `GET /api/products/[id]`
- `GET /api/categories`
