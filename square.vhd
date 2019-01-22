-- Matheus Guilherme Goncalves 9345126
-- Marcos Hora Gomes de Sรก 10394382

-- Square algoritmo
library ieee;
use ieee.numeric_bit.all;
entity square is
  port (
    X     : in  signed(7 downto 0); -- entrada
    S     : out signed(7 downto 0); -- saida
    reset : in  bit; -- reset ativo alto assicrono
--    done  : out bit; -- alto quando terminou de calcular
    clk   : in  bit;
	 teste : out signed (1 downto 0)
  );
end square;

architecture comp of square is
	component square_fd is
		port (
			X     : in  signed(7 downto 0); -- entrada
			S     : out signed(7 downto 0); -- saida
			clk   : in  bit;
			XgtY, XltY, XeqY: out bit;
			ldSquare, ldDelta, ldA, ldSqrt: in bit;
			selReg, selSoma: in bit
		);
	end component;
	
	component square_uc is
		port (
			ldSquare, ldDelta, ldA, ldSqrt: out bit;
			selReg, selSoma: out bit;
			XgtY, XltY, XeqY: in bit;
			reset: in bit;
--			done: out bit;
			clk: in bit; 
			teste : out signed (1 downto 0)
		);
	end component;
	
	signal ldSquare, ldDelta, ldA, ldSqrt, selReg, selSoma, XgtY, XltY, XeqY: bit;
begin	
	fd: square_fd port map(X, S, clk, XgtY, XltY, XeqY, ldSquare, ldDelta, ldA, ldSqrt, selReg, selSoma);
	uc: square_uc port map(ldSquare, ldDelta, ldA, ldSqrt, selReg, selSoma,XgtY, XltY, XeqY, reset, clk, teste);
end comp;

-- Square fluxo de dados
library ieee;
use ieee.numeric_bit.all;
use ieee.numeric_std;
entity square_fd is
	port (
		X     : in  signed(7 downto 0); -- entrada
		S     : out signed(7 downto 0); -- saida
		clk   : in  bit;
		XgtY, XltY, XeqY: out bit;
		ldSquare, ldDelta, ldA, ldSqrt: in bit;
		selReg, selSoma: in bit
	);
end square_fd;

architecture estrutura of square_fd is
	component registrador_8bits is
		port (
			D : in signed (7 downto 0);
			ldD: in bit;
			clock: in bit;
			Q0: out signed (7 downto 0)
		);
	end component;
	
	component mux2_1 is
		port (
			a0, b0: in signed (7 downto 0);
			sel: in bit;
			saida: out signed (7 downto 0)
		);
	end component;
	
	component comparador_8bits is
		port (
			A, B: in signed (7 downto 0);
			AgtB, AltB, AeqB: out bit
		);
	end component;
	
	component somador_8bits is
		port (
			A, B: in signed (7 downto 0);
			S0: out signed (7 downto 0)
		);
	end component;
	
	component somadorsubtrator_8bits is
		port (
			somaSub: in bit;
			M, N: in signed (7 downto 0);
			X0: out signed (7 downto 0)
		);
	end component;
	
	component shift2
		port (
			E : in  signed(7 downto 0);
			S : out signed(7 downto 0)
		);
	end component shift2;
	
signal s_regSquare, s_regDelta, s_regA: signed (7 downto 0);
signal s_muxA, s_muxB, s_muxC, s_muxD: signed (7 downto 0);
signal s_AmaisB1, s_AmaisB2: signed (7 downto 0);
signal s_shift: signed (7 downto 0);

begin
	regSquare: registrador_8bits port map (D => s_muxA, ldD => ldSquare, clock => clk, Q0 => s_regSquare);
	regDelta: registrador_8bits port map (D => s_muxB, ldD => ldDelta, clock => clk, Q0 => s_regDelta);
	regA: registrador_8bits port map(D => X, ldD => ldA, clock => clk, Q0 => s_regA);
	regSqrt: registrador_8bits port map(D => s_shift, ldD => ldSqrt, clock => clk, Q0 => S);

	
	muxA: mux2_1 port map(a0 => "00000001", b0 => s_AmaisB1, sel => selReg, saida => s_muxA);
	muxB: mux2_1 port map(a0 => "00000011", b0 => s_AmaisB2, sel => selReg, saida => s_muxB);
	
	shift: shift2 port map(s_AmaisB2, s_shift);
	
	comparador: comparador_8bits port map(A => s_regSquare, B => s_regA, AgtB => XgtY, AltB => XltY, AeqB => XeqY);
	
	somador1: somador_8bits port map(A => s_regSquare, B => s_regDelta, S0 => s_AmaisB1);
	somador2: somadorsubtrator_8bits port map(somaSub => selsoma, M => s_regDelta, N => "00000010", X0 => s_AmaisB2);
	
	
	
end estrutura;

-- Square unidade de controle
library ieee;
use ieee.numeric_bit.all;

entity square_uc is
	port (
		ldSquare, ldDelta, ldA, ldSqrt: out bit;
		selReg, selSoma: out bit;
		XgtY, XltY, XeqY: in bit;
		reset: in bit;
--		done: out bit;
		clk: in bit;
		teste : out signed (1 downto 0)
	);
end square_uc;

architecture estrutura of square_uc is
	type estado is (inicio, squareMaiorQueA, squareMenorQueA, fim);
	signal estado_atual, proximo_estado: estado;
begin
	process (reset, clk)
	begin
		if reset = '1' then
			estado_atual <= inicio;
		elsif (clk' event and clk = '1') then
			estado_atual <= proximo_estado; 
		end if;
	end process;
	
	process (estado_atual, XgtY)
	begin
		case estado_atual is
			when inicio =>
				if (XgtY = '1') then
					proximo_estado <= squareMaiorQueA;
				else
					proximo_estado <= squareMenorQueA;
				end if;
			when squareMenorQueA =>
				if (XgtY = '1') then
					proximo_estado <= squareMaiorQueA;
				else
					proximo_estado <= squareMenorQueA;
				end if;
			when squareMaiorQueA =>
				proximo_estado <= fim;
			when fim =>
				proximo_estado <= fim;
		end case;
	end process;
	
	process (estado_atual)
	begin
		ldSquare <= '0'; ldDelta <= '0';
		ldA <= '0'; ldSqrt <= '0';
		selReg <= '0'; selSoma <= '0';
		
		case estado_atual is
			when inicio =>
				ldSquare <= '1';
				ldDelta <= '1';
				ldA <= '1';
				selReg <= '1';
				teste <= "00";
			
			when squareMenorQueA =>
				ldSquare <= '1';
				ldDelta <= '1';
				teste <= "01";
				
			when squareMaiorQueA =>
				selSoma <= '1';
				ldSqrt <= '1';
				teste <= "10";
				
			when fim =>
				teste <= "11";
				
		end case;
	end process;
end estrutura;

-- Logica combinatoria
library ieee;
use ieee.numeric_bit.all;
entity mux2_1 is
	port (
		a0, b0: in signed (7 downto 0);
		sel: in bit;
		saida: out signed (7 downto 0)
	);
end mux2_1;

architecture comportamento of mux2_1 is
begin
	saida <= a0 when (sel = '1') else
		 b0 when (sel = '0');
end comportamento;

library ieee;
use ieee.numeric_bit.all;
entity registrador_8bits is
	port (
		D : in signed (7 downto 0);
		ldD: in bit;
		clock: in bit;
		Q0: out signed (7 downto 0)
	);
end registrador_8bits;

architecture comportamento of registrador_8bits is 
begin
	process (clock)
	begin
		if (clock' event and clock = '1') then
			if (ldD = '1') then
				Q0 <= D;
			end if;
		end if;
	end process;
end comportamento;

library ieee;
use ieee.numeric_bit.all;
entity comparador_8bits is
	port (
		A, B: in signed (7 downto 0);
		AeqB, AltB, AgtB: out bit
	);
end comparador_8bits;

architecture comportamento of comparador_8bits is
begin
	AeqB <= '1' when (A = B) else '0';
	AgtB <= '1' when (A > B) else '0';
	AltB <= '1' when (A < B) else '0';
end comportamento;

library ieee;
use ieee.numeric_bit.all;
entity somador_8bits is
	port (
		A, B: in signed (7 downto 0);
		S0: out signed (7 downto 0)
	);
end somador_8bits;

architecture comportamento of somador_8bits is	
begin
    S0 <= A + B;
end comportamento;

library ieee;
use ieee.numeric_bit.all;
entity somadorsubtrator_8bits is
	port (
		somaSub: in bit;
		M, N: in signed (7 downto 0);
		X0: out signed (7 downto 0)
	);
end somadorsubtrator_8bits;

architecture comportamento of somadorsubtrator_8bits is
begin
	X0 <= M + N when (somaSub = '0') else
	      M - N when (somaSub = '1');
end comportamento;

library ieee;
use ieee.numeric_bit.all;

entity shift2 is
	 port (
		E : in  signed(7 downto 0);
		S : out  signed(7 downto 0)
	 );
end entity shift2;

architecture comportamento of shift2 is
begin
	S <= "0" & E(7 downto 1);
end comportamento;



