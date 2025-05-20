
-- Banco de Dados: Ferramenta Certa

-- DROP DATABASE caso exista
DROP DATABASE IF EXISTS FerramentaCerta;
CREATE DATABASE FerramentaCerta;
USE FerramentaCerta;

-- Tabela de Clientes
CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    cpf CHAR(11) UNIQUE,
    email VARCHAR(100),
    telefone VARCHAR(20),
    endereco TEXT
);

-- Tabela de Fornecedores
CREATE TABLE Fornecedores (
    id_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    cnpj CHAR(14),
    telefone VARCHAR(20),
    email VARCHAR(100),
    endereco TEXT
);

-- Tabela de Produtos
CREATE TABLE Produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    descricao TEXT,
    preco DECIMAL(10,2),
    quantidade_estoque INT,
    id_fornecedor INT,
    FOREIGN KEY (id_fornecedor) REFERENCES Fornecedores(id_fornecedor)
);

-- Tabela de Serviços
CREATE TABLE Servicos (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    descricao TEXT,
    preco DECIMAL(10,2)
);

-- Tabela de Pedidos
CREATE TABLE Pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    data_pedido DATE,
    status ENUM('Pendente', 'Pago', 'Cancelado'),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

-- Tabela de Itens de Pedido
CREATE TABLE Itens_Pedido (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT,
    id_produto INT,
    quantidade INT,
    preco_unitario DECIMAL(10,2),
    FOREIGN KEY (id_pedido) REFERENCES Pedidos(id_pedido),
    FOREIGN KEY (id_produto) REFERENCES Produtos(id_produto)
);

-- Tabela de Logs de Alterações de Clientes
CREATE TABLE Log_Clientes (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    cpf CHAR(11),
    endereco TEXT,
    data_alteracao DATETIME
);

-- Procedure: Realizar Venda
DELIMITER //
CREATE PROCEDURE RealizarVenda(
    IN pid_cliente INT,
    IN pdata DATE
)
BEGIN
    INSERT INTO Pedidos (id_cliente, data_pedido, status)
    VALUES (pid_cliente, pdata, 'Pendente');
END;
//
DELIMITER ;

-- Procedure: Atualizar Estoque
DELIMITER //
CREATE PROCEDURE AtualizarEstoque(
    IN pid_produto INT,
    IN quantidade_comprada INT
)
BEGIN
    UPDATE Produtos
    SET quantidade_estoque = quantidade_estoque - quantidade_comprada
    WHERE id_produto = pid_produto;
END;
//
DELIMITER ;

-- Function: Validar CPF
DELIMITER //
CREATE FUNCTION ValidarCPF(cpf CHAR(11))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN LENGTH(cpf) = 11 AND cpf REGEXP '^[0-9]+$';
END;
//
DELIMITER ;

-- Function: Calcular Total do Pedido
DELIMITER //
CREATE FUNCTION CalcularTotalPedido(pid_pedido INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(quantidade * preco_unitario)
    INTO total
    FROM Itens_Pedido
    WHERE id_pedido = pid_pedido;
    RETURN total;
END;
//
DELIMITER ;

-- Trigger: Atualizar Estoque Após Venda
DELIMITER //
CREATE TRIGGER AtualizarEstoqueAposVenda
AFTER INSERT ON Itens_Pedido
FOR EACH ROW
BEGIN
    UPDATE Produtos
    SET quantidade_estoque = quantidade_estoque - NEW.quantidade
    WHERE id_produto = NEW.id_produto;
END;
//
DELIMITER ;

-- Trigger: Log de Alterações em Clientes
DELIMITER //
CREATE TRIGGER LogAlteracoesCliente
AFTER UPDATE ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO Log_Clientes (id_cliente, nome, email, cpf, endereco, data_alteracao)
    VALUES (OLD.id_cliente, OLD.nome, OLD.email, OLD.cpf, OLD.endereco, NOW());
END;
//
DELIMITER ;

-- Views
CREATE VIEW View_Pedidos_Cliente AS
SELECT c.nome AS cliente, p.id_pedido, p.data_pedido, p.status
FROM Pedidos p
JOIN Clientes c ON p.id_cliente = c.id_cliente;

CREATE VIEW View_Produtos_Mais_Vendidos AS
SELECT pr.nome, SUM(ip.quantidade) AS total_vendido
FROM Itens_Pedido ip
JOIN Produtos pr ON ip.id_produto = pr.id_produto
GROUP BY pr.nome
ORDER BY total_vendido DESC;

-- SELECTs Diversos

-- 1. Lista de clientes com pedidos
SELECT c.nome, COUNT(p.id_pedido) AS total_pedidos
FROM Clientes c
JOIN Pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.nome;

-- 2. Produtos com estoque baixo
SELECT nome, quantidade_estoque
FROM Produtos
WHERE quantidade_estoque < 5;

-- 3. Total de vendas por cliente
SELECT c.nome, SUM(ip.quantidade * ip.preco_unitario) AS total_gasto
FROM Clientes c
JOIN Pedidos p ON c.id_cliente = p.id_cliente
JOIN Itens_Pedido ip ON p.id_pedido = ip.id_pedido
GROUP BY c.nome;

-- 4. Valor médio por pedido
SELECT AVG(CalcularTotalPedido(id_pedido)) AS media_valor
FROM Pedidos;

-- 5. Produtos com maior preço
SELECT nome, preco FROM Produtos ORDER BY preco DESC LIMIT 5;

-- 6. Lista de pedidos pagos
SELECT * FROM Pedidos WHERE status = 'Pago';

-- 7. Fornecedores com mais produtos
SELECT f.nome, COUNT(p.id_produto) AS total_produtos
FROM Fornecedores f
JOIN Produtos p ON f.id_fornecedor = p.id_fornecedor
GROUP BY f.nome;

-- 8. Quantidade total de produtos vendidos
SELECT SUM(quantidade) AS total_vendido FROM Itens_Pedido;

-- 9. Produtos não vendidos
SELECT nome FROM Produtos
WHERE id_produto NOT IN (
    SELECT DISTINCT id_produto FROM Itens_Pedido
);

-- 10. Clientes com maior gasto
SELECT c.nome, SUM(ip.quantidade * ip.preco_unitario) AS total
FROM Clientes c
JOIN Pedidos p ON c.id_cliente = p.id_cliente
JOIN Itens_Pedido ip ON p.id_pedido = ip.id_pedido
GROUP BY c.nome
ORDER BY total DESC
LIMIT 1;
