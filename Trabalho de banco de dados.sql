-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 03/06/2025 às 02:56
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.1.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `teste banco`
--

DELIMITER $$
--
-- Procedimentos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AtualizarEstoque` (IN `pid_produto` INT, IN `quantidade_comprada` INT)   BEGIN
    UPDATE Produtos
    SET quantidade_estoque = quantidade_estoque - quantidade_comprada
    WHERE id_produto = pid_produto;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `RealizarVenda` (IN `pid_cliente` INT, IN `pdata` DATE)   BEGIN
    INSERT INTO Pedidos (id_cliente, data_pedido, status)
    VALUES (pid_cliente, pdata, 'Pendente');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `RelatorioMensalFuncionarios` (IN `pmes` INT, IN `pano` INT)   BEGIN
    SELECT 
        f.nome,
        f.cargo,
        COUNT(p.id_pedido) as pedidos_mes,
        COALESCE(SUM(
            CASE WHEN p.status = 'Pago' THEN 
                (SELECT SUM(ip.quantidade * ip.preco_unitario) 
                 FROM itens_pedido ip 
                 WHERE ip.id_pedido = p.id_pedido)
            ELSE 0 END
        ), 0) as vendas_mes,
        CalcularComissaoVendedor(f.id_funcionario, pmes, pano) as comissao_mes
    FROM funcionarios f
    LEFT JOIN pedidos p ON f.id_funcionario = p.id_funcionario_vendedor 
        AND MONTH(p.data_pedido) = pmes 
        AND YEAR(p.data_pedido) = pano
    WHERE f.status = 'Ativo'
    GROUP BY f.id_funcionario, f.nome, f.cargo
    ORDER BY vendas_mes DESC;
END$$

--
-- Funções
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalcularComissaoVendedor` (`pid_funcionario` INT, `pmes` INT, `pano` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE comissao DECIMAL(10,2) DEFAULT 0;
    DECLARE total_vendas DECIMAL(10,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(
        (SELECT SUM(ip.quantidade * ip.preco_unitario) 
         FROM itens_pedido ip 
         WHERE ip.id_pedido = p.id_pedido)
    ), 0) INTO total_vendas
    FROM pedidos p
    WHERE p.id_funcionario_vendedor = pid_funcionario
    AND p.status = 'Pago'
    AND MONTH(p.data_pedido) = pmes
    AND YEAR(p.data_pedido) = pano;
    
    -- Comissão de 3% sobre vendas
    SET comissao = total_vendas * 0.03;
    
    RETURN comissao;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `CalcularTotalPedido` (`pid_pedido` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(quantidade * preco_unitario)
    INTO total
    FROM Itens_Pedido
    WHERE id_pedido = pid_pedido;
    RETURN total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `ValidarCPF` (`cpf` CHAR(11)) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    RETURN LENGTH(cpf) = 11 AND cpf REGEXP '^[0-9]+$';
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `cpf` char(11) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `endereco` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `nome`, `cpf`, `email`, `telefone`, `endereco`) VALUES
(1, 'Ana Paula Souza', '12345678901', 'ana.lirio@gmail.com', '11991234567', 'Av. dos Lírios, 100 - São Paulo'),
(2, 'Carlos Eduardo Lima', '98765432100', 'carlos.lima@hotmail.com', '21988776655', 'Rua Nova Esperança, 321 - Niterói'),
(3, 'Juliana da Rocha', '45678912311', 'juliana.rocha@gmail.com', '31999998888', 'Rua Verde, 789 - Belo Horizonte');

--
-- Acionadores `clientes`
--
DELIMITER $$
CREATE TRIGGER `LogAlteracoesCliente` AFTER UPDATE ON `clientes` FOR EACH ROW BEGIN
    INSERT INTO Log_Clientes (id_cliente, nome, email, cpf, endereco, data_alteracao)
    VALUES (OLD.id_cliente, OLD.nome, OLD.email, OLD.cpf, OLD.endereco, NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `fornecedores`
--

CREATE TABLE `fornecedores` (
  `id_fornecedor` int(11) NOT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `cnpj` char(14) DEFAULT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `endereco` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `fornecedores`
--

INSERT INTO `fornecedores` (`id_fornecedor`, `nome`, `cnpj`, `telefone`, `email`, `endereco`) VALUES
(1, 'Ferragens Brasil LTDA', '12345678000199', '1133221100', 'contato@ferragensbr.com', 'Av. Industrial, 1000 - São Paulo'),
(2, 'Parafusos e Cia ME', '98765432000188', '1144556600', 'vendas@parafusosecia.com', 'Rua das Indústrias, 800 - Campinas');

-- --------------------------------------------------------

--
-- Estrutura para tabela `funcionarios`
--

CREATE TABLE `funcionarios` (
  `id_funcionario` int(11) NOT NULL,
  `nome` varchar(100) NOT NULL,
  `cpf` char(11) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `endereco` text DEFAULT NULL,
  `cargo` varchar(50) NOT NULL,
  `salario` decimal(10,2) DEFAULT NULL,
  `data_admissao` date NOT NULL,
  `data_demissao` date DEFAULT NULL,
  `status` enum('Ativo','Inativo','Licenca') DEFAULT 'Ativo',
  `id_supervisor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `funcionarios`
--

INSERT INTO `funcionarios` (`id_funcionario`, `nome`, `cpf`, `email`, `telefone`, `endereco`, `cargo`, `salario`, `data_admissao`, `data_demissao`, `status`, `id_supervisor`) VALUES
(1, 'Maria Silva Santos', '11122233344', 'maria.silva@empresa.com', '11987654321', 'Rua das Acácias, 200 - São Paulo', 'Gerente de Vendas', 4500.00, '2023-01-15', NULL, 'Ativo', NULL),
(2, 'João Pedro Oliveira', '22233344455', 'joao.pedro@empresa.com', '11976543210', 'Av. Paulista, 1500 - São Paulo', 'Vendedor', 2800.00, '2023-03-20', NULL, 'Ativo', 1),
(3, 'Fernanda Costa Lima', '33344455566', 'fernanda.costa@empresa.com', '11965432109', 'Rua Augusta, 800 - São Paulo', 'Técnica em Serviços', 3200.00, '2023-02-10', NULL, 'Ativo', 1),
(4, 'Roberto Almeida', '44455566677', 'roberto.almeida@empresa.com', '11954321098', 'Rua Oscar Freire, 300 - São Paulo', 'Supervisor de Estoque', 3800.00, '2022-11-05', NULL, 'Ativo', 1);

--
-- Acionadores `funcionarios`
--
DELIMITER $$
CREATE TRIGGER `LogAlteracoesFuncionario` AFTER UPDATE ON `funcionarios` FOR EACH ROW BEGIN
    INSERT INTO log_funcionarios (id_funcionario, nome_anterior, cargo_anterior, salario_anterior, status_anterior, data_alteracao)
    VALUES (OLD.id_funcionario, OLD.nome, OLD.cargo, OLD.salario, OLD.status, NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `itens_pedido`
--

CREATE TABLE `itens_pedido` (
  `id_item` int(11) NOT NULL,
  `id_pedido` int(11) DEFAULT NULL,
  `id_produto` int(11) DEFAULT NULL,
  `quantidade` int(11) DEFAULT NULL,
  `preco_unitario` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `itens_pedido`
--

INSERT INTO `itens_pedido` (`id_item`, `id_pedido`, `id_produto`, `quantidade`, `preco_unitario`) VALUES
(1, 1, 1, 1, 299.90),
(2, 1, 2, 10, 0.50),
(3, 2, 3, 2, 14.90);

--
-- Acionadores `itens_pedido`
--
DELIMITER $$
CREATE TRIGGER `AtualizarEstoqueAposVenda` AFTER INSERT ON `itens_pedido` FOR EACH ROW BEGIN
    UPDATE Produtos
    SET quantidade_estoque = quantidade_estoque - NEW.quantidade
    WHERE id_produto = NEW.id_produto;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `log_clientes`
--

CREATE TABLE `log_clientes` (
  `id_log` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `cpf` char(11) DEFAULT NULL,
  `endereco` text DEFAULT NULL,
  `data_alteracao` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `log_clientes`
--

INSERT INTO `log_clientes` (`id_log`, `id_cliente`, `nome`, `email`, `cpf`, `endereco`, `data_alteracao`) VALUES
(1, 1, 'Ana Paula Souza', 'ana.souza@gmail.com', '12345678901', 'Rua das Flores, 123 - São Paulo', '2025-05-27 14:28:24'),
(2, 1, 'Ana Paula Souza', 'ana.souza.novoemail@gmail.com', '12345678901', 'Rua das Magnólias, 456 - São Paulo', '2025-05-27 14:29:13'),
(3, 2, 'Carlos Eduardo Lima', 'carlos.lima@hotmail.com', '98765432100', 'Av. Central, 456 - Rio de Janeiro', '2025-05-27 14:29:13'),
(4, 3, 'Juliana Rocha', 'juliana.rocha@gmail.com', '45678912311', 'Rua Verde, 789 - Belo Horizonte', '2025-05-27 14:29:13'),
(5, 1, 'Ana Paula Souza', 'ana.paula.souza@outlook.com', '12345678901', 'Rua das Magnólias, 456 - São Paulo', '2025-05-27 14:29:13');

-- --------------------------------------------------------

--
-- Estrutura para tabela `log_funcionarios`
--

CREATE TABLE `log_funcionarios` (
  `id_log` int(11) NOT NULL,
  `id_funcionario` int(11) NOT NULL,
  `nome_anterior` varchar(100) DEFAULT NULL,
  `cargo_anterior` varchar(50) DEFAULT NULL,
  `salario_anterior` decimal(10,2) DEFAULT NULL,
  `status_anterior` enum('Ativo','Inativo','Licenca') DEFAULT NULL,
  `data_alteracao` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `data_pedido` date DEFAULT NULL,
  `status` enum('Pendente','Pago','Cancelado') DEFAULT NULL,
  `id_funcionario_vendedor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_cliente`, `data_pedido`, `status`, `id_funcionario_vendedor`) VALUES
(1, 1, '2025-05-01', 'Pago', 2),
(2, 2, '2025-05-03', 'Pendente', 2),
(3, 3, '2025-05-05', 'Cancelado', 1);

-- --------------------------------------------------------

--
-- Estrutura para tabela `produtos`
--

CREATE TABLE `produtos` (
  `id_produto` int(11) NOT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `descricao` text DEFAULT NULL,
  `preco` decimal(10,2) DEFAULT NULL,
  `quantidade_estoque` int(11) DEFAULT NULL,
  `id_fornecedor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produtos`
--

INSERT INTO `produtos` (`id_produto`, `nome`, `descricao`, `preco`, `quantidade_estoque`, `id_fornecedor`) VALUES
(1, 'Furadeira Bosch 500W', 'Furadeira elétrica de uso doméstico e profissional', 299.90, 14, 1),
(2, 'Parafuso Phillips 4mm', 'Parafuso com cabeça Phillips e 4mm de espessura', 0.50, 190, 2),
(3, 'Chave de Fenda Tramontina', 'Chave de fenda com cabo ergonômico', 14.90, 28, 1),
(4, 'Serra Circular 7.1/4\"', 'Serra circular para cortes em madeira', 399.99, 5, 1);

-- --------------------------------------------------------

--
-- Estrutura para tabela `servicos`
--

CREATE TABLE `servicos` (
  `id_servico` int(11) NOT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `descricao` text DEFAULT NULL,
  `preco` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `servicos`
--

INSERT INTO `servicos` (`id_servico`, `nome`, `descricao`, `preco`) VALUES
(1, 'Instalação de Prateleiras', 'Serviço de instalação de prateleiras em residências ou comércios', 120.00),
(2, 'Montagem de Móveis', 'Montagem de móveis simples e complexos', 180.00),
(3, 'Troca de Torneiras', 'Troca de torneiras em pias ou tanques', 90.00);

-- --------------------------------------------------------

--
-- Estrutura para tabela `servicos_funcionarios`
--

CREATE TABLE `servicos_funcionarios` (
  `id_servico_funcionario` int(11) NOT NULL,
  `id_servico` int(11) NOT NULL,
  `id_funcionario` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `data_execucao` date NOT NULL,
  `observacoes` text DEFAULT NULL,
  `status` enum('Agendado','Em_Andamento','Concluido','Cancelado') DEFAULT 'Agendado'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `servicos_funcionarios`
--

INSERT INTO `servicos_funcionarios` (`id_servico_funcionario`, `id_servico`, `id_funcionario`, `id_cliente`, `data_execucao`, `observacoes`, `status`) VALUES
(1, 1, 3, 1, '2025-05-10', NULL, 'Concluido'),
(2, 2, 3, 2, '2025-05-15', NULL, 'Em_Andamento'),
(3, 3, 3, 3, '2025-05-20', NULL, 'Agendado');

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `view_pedidos_cliente`
-- (Veja abaixo para a visão atual)
--
CREATE TABLE `view_pedidos_cliente` (
`cliente` varchar(100)
,`id_pedido` int(11)
,`data_pedido` date
,`status` enum('Pendente','Pago','Cancelado')
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `view_produtos_mais_vendidos`
-- (Veja abaixo para a visão atual)
--
CREATE TABLE `view_produtos_mais_vendidos` (
`nome` varchar(100)
,`total_vendido` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `view_servicos_funcionario`
-- (Veja abaixo para a visão atual)
--
CREATE TABLE `view_servicos_funcionario` (
`funcionario` varchar(100)
,`servico` varchar(100)
,`cliente` varchar(100)
,`data_execucao` date
,`status` enum('Agendado','Em_Andamento','Concluido','Cancelado')
,`preco` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `view_vendas_funcionario`
-- (Veja abaixo para a visão atual)
--
CREATE TABLE `view_vendas_funcionario` (
`funcionario` varchar(100)
,`cargo` varchar(50)
,`total_pedidos` bigint(21)
,`pedidos_pagos` decimal(22,0)
,`total_vendas` decimal(64,2)
);

-- --------------------------------------------------------

--
-- Estrutura para view `view_pedidos_cliente`
--
DROP TABLE IF EXISTS `view_pedidos_cliente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pedidos_cliente`  AS SELECT `c`.`nome` AS `cliente`, `p`.`id_pedido` AS `id_pedido`, `p`.`data_pedido` AS `data_pedido`, `p`.`status` AS `status` FROM (`pedidos` `p` join `clientes` `c` on(`p`.`id_cliente` = `c`.`id_cliente`)) ;

-- --------------------------------------------------------

--
-- Estrutura para view `view_produtos_mais_vendidos`
--
DROP TABLE IF EXISTS `view_produtos_mais_vendidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_produtos_mais_vendidos`  AS SELECT `pr`.`nome` AS `nome`, sum(`ip`.`quantidade`) AS `total_vendido` FROM (`itens_pedido` `ip` join `produtos` `pr` on(`ip`.`id_produto` = `pr`.`id_produto`)) GROUP BY `pr`.`nome` ORDER BY sum(`ip`.`quantidade`) DESC ;

-- --------------------------------------------------------

--
-- Estrutura para view `view_servicos_funcionario`
--
DROP TABLE IF EXISTS `view_servicos_funcionario`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_servicos_funcionario`  AS SELECT `f`.`nome` AS `funcionario`, `s`.`nome` AS `servico`, `c`.`nome` AS `cliente`, `sf`.`data_execucao` AS `data_execucao`, `sf`.`status` AS `status`, `s`.`preco` AS `preco` FROM (((`servicos_funcionarios` `sf` join `funcionarios` `f` on(`sf`.`id_funcionario` = `f`.`id_funcionario`)) join `servicos` `s` on(`sf`.`id_servico` = `s`.`id_servico`)) join `clientes` `c` on(`sf`.`id_cliente` = `c`.`id_cliente`)) ORDER BY `sf`.`data_execucao` DESC ;

-- --------------------------------------------------------

--
-- Estrutura para view `view_vendas_funcionario`
--
DROP TABLE IF EXISTS `view_vendas_funcionario`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_vendas_funcionario`  AS SELECT `f`.`nome` AS `funcionario`, `f`.`cargo` AS `cargo`, count(`p`.`id_pedido`) AS `total_pedidos`, sum(case when `p`.`status` = 'Pago' then 1 else 0 end) AS `pedidos_pagos`, coalesce(sum(case when `p`.`status` = 'Pago' then (select sum(`ip`.`quantidade` * `ip`.`preco_unitario`) from `itens_pedido` `ip` where `ip`.`id_pedido` = `p`.`id_pedido`) else 0 end),0) AS `total_vendas` FROM (`funcionarios` `f` left join `pedidos` `p` on(`f`.`id_funcionario` = `p`.`id_funcionario_vendedor`)) WHERE `f`.`status` = 'Ativo' GROUP BY `f`.`id_funcionario`, `f`.`nome`, `f`.`cargo` ORDER BY coalesce(sum(case when `p`.`status` = 'Pago' then (select sum(`ip`.`quantidade` * `ip`.`preco_unitario`) from `itens_pedido` `ip` where `ip`.`id_pedido` = `p`.`id_pedido`) else 0 end),0) DESC ;

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `cpf` (`cpf`);

--
-- Índices de tabela `fornecedores`
--
ALTER TABLE `fornecedores`
  ADD PRIMARY KEY (`id_fornecedor`);

--
-- Índices de tabela `funcionarios`
--
ALTER TABLE `funcionarios`
  ADD PRIMARY KEY (`id_funcionario`),
  ADD UNIQUE KEY `cpf` (`cpf`),
  ADD KEY `id_supervisor` (`id_supervisor`);

--
-- Índices de tabela `itens_pedido`
--
ALTER TABLE `itens_pedido`
  ADD PRIMARY KEY (`id_item`),
  ADD KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_produto` (`id_produto`);

--
-- Índices de tabela `log_clientes`
--
ALTER TABLE `log_clientes`
  ADD PRIMARY KEY (`id_log`);

--
-- Índices de tabela `log_funcionarios`
--
ALTER TABLE `log_funcionarios`
  ADD PRIMARY KEY (`id_log`),
  ADD KEY `id_funcionario` (`id_funcionario`);

--
-- Índices de tabela `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_funcionario_vendedor` (`id_funcionario_vendedor`);

--
-- Índices de tabela `produtos`
--
ALTER TABLE `produtos`
  ADD PRIMARY KEY (`id_produto`),
  ADD KEY `id_fornecedor` (`id_fornecedor`);

--
-- Índices de tabela `servicos`
--
ALTER TABLE `servicos`
  ADD PRIMARY KEY (`id_servico`);

--
-- Índices de tabela `servicos_funcionarios`
--
ALTER TABLE `servicos_funcionarios`
  ADD PRIMARY KEY (`id_servico_funcionario`),
  ADD KEY `id_servico` (`id_servico`),
  ADD KEY `id_funcionario` (`id_funcionario`),
  ADD KEY `id_cliente` (`id_cliente`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `fornecedores`
--
ALTER TABLE `fornecedores`
  MODIFY `id_fornecedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `funcionarios`
--
ALTER TABLE `funcionarios`
  MODIFY `id_funcionario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `itens_pedido`
--
ALTER TABLE `itens_pedido`
  MODIFY `id_item` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `log_clientes`
--
ALTER TABLE `log_clientes`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de tabela `log_funcionarios`
--
ALTER TABLE `log_funcionarios`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `produtos`
--
ALTER TABLE `produtos`
  MODIFY `id_produto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `servicos`
--
ALTER TABLE `servicos`
  MODIFY `id_servico` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `servicos_funcionarios`
--
ALTER TABLE `servicos_funcionarios`
  MODIFY `id_servico_funcionario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `funcionarios`
--
ALTER TABLE `funcionarios`
  ADD CONSTRAINT `funcionarios_ibfk_1` FOREIGN KEY (`id_supervisor`) REFERENCES `funcionarios` (`id_funcionario`);

--
-- Restrições para tabelas `itens_pedido`
--
ALTER TABLE `itens_pedido`
  ADD CONSTRAINT `itens_pedido_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`),
  ADD CONSTRAINT `itens_pedido_ibfk_2` FOREIGN KEY (`id_produto`) REFERENCES `produtos` (`id_produto`);

--
-- Restrições para tabelas `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`),
  ADD CONSTRAINT `pedidos_ibfk_2` FOREIGN KEY (`id_funcionario_vendedor`) REFERENCES `funcionarios` (`id_funcionario`);

--
-- Restrições para tabelas `produtos`
--
ALTER TABLE `produtos`
  ADD CONSTRAINT `produtos_ibfk_1` FOREIGN KEY (`id_fornecedor`) REFERENCES `fornecedores` (`id_fornecedor`);

--
-- Restrições para tabelas `servicos_funcionarios`
--
ALTER TABLE `servicos_funcionarios`
  ADD CONSTRAINT `servicos_funcionarios_ibfk_1` FOREIGN KEY (`id_servico`) REFERENCES `servicos` (`id_servico`),
  ADD CONSTRAINT `servicos_funcionarios_ibfk_2` FOREIGN KEY (`id_funcionario`) REFERENCES `funcionarios` (`id_funcionario`),
  ADD CONSTRAINT `servicos_funcionarios_ibfk_3` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`);
COMMIT;

--
-- SELECTS
--

-- 1 - Visualizar pedidos existentes (contexto inicial)
SELECT 
    p.id_pedido,
    c.nome AS cliente,
    p.data_pedido,
    p.status,
    f.nome AS vendedor
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN funcionarios f ON p.id_funcionario_vendedor = f.id_funcionario
ORDER BY p.id_pedido;

-- 2 - Mostrar produtos com quantidade em estoque abaixo de um limite
SELECT
    nome AS NomeProduto,
    quantidade_estoque AS QuantidadeEmEstoque,
    preco AS PrecoUnitario
FROM
    produtos
WHERE
    quantidade_estoque < 20;

-- 3 - Calcular total de todos os pedidos usando a função
SELECT 
    p.id_pedido,
    c.nome AS cliente,
    p.data_pedido,
    p.status,
    CalcularTotalPedido(p.id_pedido) AS total_pedido
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
ORDER BY p.id_pedido;

-- 4 - Top 3 maiores pedidos
SELECT 
    p.id_pedido,
    c.nome AS cliente,
    p.data_pedido,
    CalcularTotalPedido(p.id_pedido) AS total_pedido
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE p.status = 'Pago'
ORDER BY CalcularTotalPedido(p.id_pedido) DESC
LIMIT 3;

-- 5 - Verificar CPFs de todos os clientes
SELECT 
    nome,
    cpf,
    ValidarCPF(cpf) AS cpf_valido,
    CASE 
        WHEN ValidarCPF(cpf) = 1 THEN 'Válido'
        ELSE 'Inválido'
    END AS status_cpf
FROM clientes
ORDER BY ValidarCPF(cpf) DESC, nome;

-- 6 - Listar apenas registros com CPF inválido (para correção)
SELECT 
    'Cliente' AS tipo,
    nome,
    cpf,
    'CPF inválido - necessita correção' AS observacao
FROM clientes
WHERE ValidarCPF(cpf) = 0
UNION ALL
SELECT 
    'Funcionário' AS tipo,
    nome,
    cpf,
    'CPF inválido - necessita correção' AS observacao
FROM funcionarios
WHERE ValidarCPF(cpf) = 0;

-- 7 - Comissão de todos os funcionários para maio/2025
SELECT 
    f.nome AS funcionario,
    f.cargo,
    f.status,
    CalcularComissaoVendedor(f.id_funcionario, 5, 2025) AS comissao_maio
FROM funcionarios f
WHERE f.status = 'Ativo'
ORDER BY CalcularComissaoVendedor(f.id_funcionario, 5, 2025) DESC;

-- 8 - Relatório completo: cliente, pedido, total, vendedor, comissão
SELECT 
    c.nome AS cliente,
    ValidarCPF(c.cpf) AS cliente_cpf_valido,
    p.id_pedido,
    p.data_pedido,
    p.status,
    CalcularTotalPedido(p.id_pedido) AS total_pedido,
    f.nome AS vendedor,
    CalcularComissaoVendedor(f.id_funcionario, 
                           MONTH(p.data_pedido), 
                           YEAR(p.data_pedido)) AS comissao_vendedor
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN funcionarios f ON p.id_funcionario_vendedor = f.id_funcionario
WHERE p.status = 'Pago'
ORDER BY p.data_pedido DESC;

-- 9 - Análise de performance por vendedor (maio/2025)
SELECT 
    f.nome AS vendedor,
    f.cargo,
    ValidarCPF(f.cpf) AS cpf_valido,
    COUNT(p.id_pedido) AS total_pedidos,
    SUM(CASE WHEN p.status = 'Pago' THEN 1 ELSE 0 END) AS pedidos_pagos,
    SUM(CASE WHEN p.status = 'Cancelado' THEN 1 ELSE 0 END) AS pedidos_cancelados,
    ROUND(
        (SUM(CASE WHEN p.status = 'Pago' THEN 1 ELSE 0 END) * 100.0) / 
        NULLIF(COUNT(p.id_pedido), 0), 2
    ) AS taxa_conversao,
    SUM(CASE WHEN p.status = 'Pago' THEN CalcularTotalPedido(p.id_pedido) ELSE 0 END) AS total_vendas,
    CalcularComissaoVendedor(f.id_funcionario, 5, 2025) AS comissao
FROM funcionarios f
LEFT JOIN pedidos p ON f.id_funcionario = p.id_funcionario_vendedor 
    AND MONTH(p.data_pedido) = 5 
    AND YEAR(p.data_pedido) = 2025
WHERE f.status = 'Ativo'
  AND f.cargo IN ('Vendedor', 'Gerente de Vendas')
GROUP BY f.id_funcionario, f.nome, f.cargo, f.cpf
ORDER BY total_vendas DESC;

-- 10 - Contar clientes com CPF válido vs inválido
SELECT 
    CASE 
        WHEN ValidarCPF(cpf) = 1 THEN 'CPF Válido'
        ELSE 'CPF Inválido'
    END AS status_cpf,
    COUNT(*) AS quantidade
FROM clientes
GROUP BY ValidarCPF(cpf);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
