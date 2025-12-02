-- Prática 3: minimundo posto_combustivel
-- Cria esquema, índices, dados de exemplo, view e consultas úteis

-- Tabelas
CREATE TABLE IF NOT EXISTS combustivel (
  combustivel_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  estoque_l NUMERIC(12,3) NOT NULL DEFAULT 0,
  CONSTRAINT combustivel_nome_uniq UNIQUE (nome)
);

CREATE TABLE IF NOT EXISTS funcionario (
  funcionario_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS venda (
  venda_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  data_hora TIMESTAMPTZ NOT NULL DEFAULT now(),
  funcionario_id INT REFERENCES funcionario(funcionario_id) ON DELETE SET NULL,
  total NUMERIC(12,2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE IF NOT EXISTS venda_item (
  venda_item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  venda_id INT NOT NULL REFERENCES venda(venda_id) ON DELETE CASCADE,
  combustivel_id INT NOT NULL REFERENCES combustivel(combustivel_id),
  quantidade_l NUMERIC(12,3) NOT NULL CHECK (quantidade_l >= 0),
  preco_unitario NUMERIC(12,4) NOT NULL CHECK (preco_unitario >= 0)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_venda_data_hora ON venda (data_hora);
CREATE INDEX IF NOT EXISTS idx_venda_item_combustivel ON venda_item (combustivel_id);

-- Dados de exemplo
INSERT INTO combustivel (nome, estoque_l) VALUES
  ('Gasolina', 1200.5),
  ('Etanol',  800.25),
  ('Diesel S10', 1500.0)
ON CONFLICT DO NOTHING;

INSERT INTO funcionario (nome, ativo) VALUES
  ('Ana Silva', true),
  ('José Maria', true)
ON CONFLICT DO NOTHING;

INSERT INTO venda (data_hora, funcionario_id, total) VALUES
  ('2025-11-01 09:15:00-03', 1, 210.04),
  ('2025-11-01 10:05:00-03', 2, 150.12),
  ('2025-11-01 11:00:00-03', 1,  50.15),
  ('2025-11-01 11:30:00-03', 1,  80.28),
  ('2025-11-01 11:32:00-03', 2, 110.16),
  ('2025-11-01 12:32:00-03', 2, 217.50)
ON CONFLICT DO NOTHING;

INSERT INTO venda_item (venda_id, combustivel_id, quantidade_l, preco_unitario) VALUES
  (1, 1, 35.6, 5.9),
  (2, 2, 41.7, 3.6),
  (3, 1,  8.5, 5.9),
  (4, 2, 22.3, 3.6),
  (5, 2, 30.6, 3.6),
  (6, 3, 37.5, 5.8)
ON CONFLICT DO NOTHING;

-- View de resumo por combustível (inclui preço médio seguro contra divisão por zero)
CREATE OR REPLACE VIEW resumo_venda_combustivel AS
SELECT
  c.combustivel_id,
  c.nome,
  SUM(vi.quantidade_l) AS litros_vendidos,
  SUM(vi.quantidade_l * vi.preco_unitario) AS valor_vendido,
  SUM(vi.quantidade_l * vi.preco_unitario) / NULLIF(SUM(vi.quantidade_l),0) AS preco_medio_por_litro
FROM combustivel c
JOIN venda_item vi ON vi.combustivel_id = c.combustivel_id
GROUP BY c.combustivel_id, c.nome;

-- Consultas úteis de exemplo
-- 1) Listar combustíveis por estoque decrescente
SELECT c.combustivel_id, c.nome, c.estoque_l FROM combustivel c ORDER BY c.estoque_l DESC;

-- 2) Combustíveis com estoque > 1000
SELECT c.combustivel_id, c.nome, c.estoque_l FROM combustivel c WHERE c.estoque_l > 1000 ORDER BY c.estoque_l DESC;

-- 3) Total vendido por funcionário (filtro por data e ordenado)
SELECT f.nome, SUM(v.total) AS total_funcionario
FROM funcionario f
JOIN venda v ON v.funcionario_id = f.funcionario_id
WHERE v.data_hora >= '2025-11-01 00:00:00-03' AND v.data_hora < '2025-11-02 00:00:00-03'
GROUP BY f.nome
ORDER BY total_funcionario DESC;

-- 4) Total vendido por combustível (valor e litros)
SELECT c.combustivel_id, c.nome, SUM(vi.quantidade_l * vi.preco_unitario) AS valor_vendido, SUM(vi.quantidade_l) AS litros_vendidos
FROM combustivel c
JOIN venda_item vi ON vi.combustivel_id = c.combustivel_id
GROUP BY c.combustivel_id, c.nome
ORDER BY valor_vendido DESC;

-- 5) Consultar a view de resumo
SELECT * FROM resumo_venda_combustivel ORDER BY valor_vendido DESC;

-- 6) Listar funcionários sem vendas
SELECT f.funcionario_id, f.nome FROM funcionario f LEFT JOIN venda v ON v.funcionario_id = f.funcionario_id WHERE v.venda_id IS NULL;

-- Instrução para limpar (opcional)
-- DROP VIEW IF EXISTS resumo_venda_combustivel;
-- DROP TABLE IF EXISTS venda_item, venda, combustivel, funcionario CASCADE;
