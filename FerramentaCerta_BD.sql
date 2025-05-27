
-- Banco de Dados exportado xampp: Ferramenta Certa 

-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 27/05/2025 às 19:36
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `ferramentacerta`
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

--
-- Funções
--
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
-- Estrutura para tabela `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `data_pedido` date DEFAULT NULL,
  `status` enum('Pendente','Pago','Cancelado') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_cliente`, `data_pedido`, `status`) VALUES
(1, 1, '2025-05-01', 'Pago'),
(2, 2, '2025-05-03', 'Pendente'),
(3, 3, '2025-05-05', 'Cancelado');

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
-- Índices de tabela `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `id_cliente` (`id_cliente`);

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
-- Restrições para tabelas despejadas
--

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
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`);

--
-- Restrições para tabelas `produtos`
--
ALTER TABLE `produtos`
  ADD CONSTRAINT `produtos_ibfk_1` FOREIGN KEY (`id_fornecedor`) REFERENCES `fornecedores` (`id_fornecedor`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;