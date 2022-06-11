library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Square is
  port ( CLK_24MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			key				: in std_logic_vector(3 downto 0);
			SevenSeg 		: out std_logic_vector(7 downto 0);
			EN 				: out std_logic_vector(3 downto 0);
			SW					: in std_logic_vector(7 downto 0);
			LED				: out std_logic_vector(7 downto 0)
			
  );
end VGA_Square;

architecture Behavioral of VGA_Square is

	function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
	begin
		return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
	end function;
	
	function sevensegment (input :in integer ) return std_logic_vector is 
   variable output: std_logic_vector(7 downto 0);
	begin
			if input = 0 then output :=x"c0";
			elsif input = 1 then output := x"f9";
			elsif input = 2 then output := x"a4";
			elsif input = 3 then output := x"b0";
			elsif input = 4 then output := x"99";
			elsif input = 5 then output := x"92";
			elsif input = 6 then output := x"82";
			elsif input = 7 then output := x"f8";
			elsif input = 8 then output := x"80";
			elsif input = 9 then output := x"98";
			else output:="11000000";
		end if;
		return output;
	end function sevensegment;

  signal ColorOutput: std_logic_vector(5 downto 0);
  signal BulletHoleX: std_logic_vector(9 downto 0) := "0101001010";  
  signal BulletHoleY: std_logic_vector(9 downto 0) := "0101000000";
  signal PlayerX: std_logic_vector(9 downto 0) := "0101000000";  
  signal PlayerY: std_logic_vector(9 downto 0) := "0101000000";
  signal Block0X: std_logic_vector(9 downto 0) := "0000000000";  
  signal Block0Y: std_logic_vector(9 downto 0) := "0000000000";
  signal Block0Width: std_logic_vector(9 downto 0) := "0000011001";
  signal Block0Height: std_logic_vector(9 downto 0) := "0000011001";
  signal Block1X: std_logic_vector(9 downto 0) := "0000000000";  
  signal Block1Y: std_logic_vector(9 downto 0) := "0000011001";
  signal Block1Width: std_logic_vector(9 downto 0) := "0000011001";
  signal Block1Height: std_logic_vector(9 downto 0) := "0000110010";
  signal Block2X: std_logic_vector(9 downto 0) := "0000000000";  
  signal Block2Y: std_logic_vector(9 downto 0) := "0010100000";
  signal Block2Width: std_logic_vector(9 downto 0) := "0000011001";
  signal Block2Height: std_logic_vector(9 downto 0) := "0001001011";
  signal Block3X: std_logic_vector(9 downto 0) := "0000000000";  
  signal Block3Y: std_logic_vector(9 downto 0) := "0010111001";
  signal Block3Width: std_logic_vector(9 downto 0) := "0000110010";
  signal Block3Height: std_logic_vector(9 downto 0) := "0000011001";
  signal Block4X: std_logic_vector(9 downto 0) := "0000000000";  
  signal Block4Y: std_logic_vector(9 downto 0) := "0100000100";
  signal Block4Width: std_logic_vector(9 downto 0) := "0000110010";
  signal Block4Height: std_logic_vector(9 downto 0) := "0000110010";
  signal Block5X: std_logic_vector(9 downto 0) := "0000000000";  
  signal Block5Y: std_logic_vector(9 downto 0) := "0001011101";
  signal Block5Width: std_logic_vector(9 downto 0) := "0000110010";
  signal Block5Height: std_logic_vector(9 downto 0) := "0001001011";
  signal pushdown : integer range 0 to 302 := 0;
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal sevens1, sevens2, sevens3, sevens4 : std_logic_vector(7 downto 0) := (others => '0');
  signal templed : std_logic_vector(7 downto 0) := (others => '0');
  signal temptempled : std_logic_vector(7 downto 0) := (others => '1');
  signal rand: std_logic_vector(31 downto 0) := (others => '0');
  signal sscounter: integer range 0 to 80001 := 0;
  signal initcounter: integer range 0 to 24000000 := 0;
  signal playercounter: integer range 0 to 120001 := 0;
  signal aiplayercounter: integer range 0 to 90001 := 0;
  signal lookaheadcounter: integer range 0 to 10000 := 0;
  signal gamecounter: integer range 0 to 200000 := 0;
  signal gamespeed : integer range 0 to 200000 := 200000;
  signal tempspeed : integer range 0 to 200000 := 200000;
  signal timercounter: integer range 0 to 24000001 := 0;
  signal dancecounter: integer range 0 to 72000000 := 0;
  signal bulletmovecounter: integer range 0 to 50000 := 0;
  signal bulletcounter: integer range 0 to 3000000 := 0;
  signal timer0, timer1 : integer range 0 to 10 := 0;
  signal maintimer : integer range 0 to 99 := 0;
  signal point : integer range 0 to 99 := 0;
  signal speedtimer : integer range 0 to 14 := 0;
  signal bulletindex : integer range 0 to 8 := 0;
  signal finalstate : std_logic := '0';
  type arr13 is array(0 to 12) of std_logic_vector(9 downto 0);
  type arr7 is array(0 to 6) of std_logic_vector(9 downto 0);
  type arr8 is array(0 to 7) of std_logic_vector(9 downto 0);
  type arr5 is array(0 to 4) of std_logic_vector(9 downto 0);
  signal BulletX : arr8 := (others => (others => '0'));
  signal BulletY : arr8 := (others => (others => '0'));
  signal BulletWidth : std_logic_vector(9 downto 0) := "0000000101";
  signal x25 : arr13 := ("0010100000", "0010111001", "0011010010", "0011101011", "0100000100", "0100011101", "0100110110", "0101001111", "0101101000", "0110000001", "0110011010", "0110110011", "0111001100");
  signal x50 : arr7 := ("0010100000", "0011010010", "0100000100", "0100110110", "0101101000", "0110011010", "0111001100");
  signal x75 : arr5 := ("0010100000", "0011101011", "0100110110", "0110000001", "0111001100");
  type fsm is (init, weit, game, endgame);
  signal p_s : fsm := init;
  signal aimode : std_logic := '0';
  signal lookahead : integer range 160 to 455 := 320;
  signal safezone : integer range 160 to 455 := 320;
begin

	PrescalerCounter: process(CLK_24MHz, RESET)
	begin
		if RESET = '1' then
			initcounter <= 0;
			gamecounter <= 0;
			gamespeed <= 200000;
			tempspeed <= 200000;
			timercounter <= 0;
			dancecounter <= 0;
			timer0 <= 0;
			timer1 <= 0;
			maintimer <= 0;
			point <= 0;
			speedtimer <= 0;
			pushdown <= 0;
			templed <= (others => '0');
			finalstate <= '0';
			Block0Y <= "0000000000";
			Block1Y <= "0000011001";
			Block2Y <= "0010100000";
			Block3Y <= "0010111001";
			Block4Y <= "0100000100";
			Block5Y <= "0001011101";
			p_s <= init;
			aimode <= '0';
		elsif rising_edge(CLK_24MHz) then
			p_s <= p_s;
			initcounter <= initcounter + 1;
			rand <= lfsr32(rand);
			case p_s is
				when init =>
					sevens1 <= "11000000";
					sevens2 <= "10100100";
					sevens3 <= "11111001";
					sevens4 <= "10000000";
					gamecounter <= 0;
					gamespeed <= 200000;
					tempspeed <= 200000;
					timercounter <= 0;
					dancecounter <= 0;
					timer0 <= 0;
					timer1 <= 0;
					maintimer <= 0;
					point <= 0;
					speedtimer <= 0;
					pushdown <= 0;
					templed <= (others => '0');
					temptempled <= (others => '1');
					finalstate <= '0';
					aimode <= '0';
					Block0Y <= "0000000000";
					Block1Y <= "0000011001";
					Block2Y <= "0010100000";
					Block3Y <= "0010111001";
					Block4Y <= "0100000100";
					Block5Y <= "0001011101";
					if initcounter = 24000000 then
						p_s <= weit;
						case rand(3 downto 0) is
							when "0000"=> Block0X <= x25(0);
							when "0001"=> Block0X <= x25(1);
							when "0010"=> Block0X <= x25(2);
							when "0011"=> Block0X <= x25(3);
							when "0100"=> Block0X <= x25(4);
							when "0101"=> Block0X <= x25(5);
							when "0110"=> Block0X <= x25(6);
							when "0111"=> Block0X <= x25(7);
							when "1000"=> Block0X <= x25(8);
							when "1001"=> Block0X <= x25(9);
							when "1010"=> Block0X <= x25(10);
							when "1011"=> Block0X <= x25(11);
							when "1100"=> Block0X <= x25(12);
							when others => Block0X <= x25(0);
						end case;
						case rand(6 downto 3) is
							when "0000"=> Block1X <= x25(0);
							when "0001"=> Block1X <= x25(1);
							when "0010"=> Block1X <= x25(2);
							when "0011"=> Block1X <= x25(3);
							when "0100"=> Block1X <= x25(4);
							when "0101"=> Block1X <= x25(5);
							when "0110"=> Block1X <= x25(6);
							when "0111"=> Block1X <= x25(7);
							when "1000"=> Block1X <= x25(8);
							when "1001"=> Block1X <= x25(9);
							when "1010"=> Block1X <= x25(10);
							when "1011"=> Block1X <= x25(11);
							when "1100"=> Block1X <= x25(12);
							when others => Block1X <= x25(0);
						end case;
						case rand(9 downto 6) is
							when "0000"=> Block2X <= x25(0);
							when "0001"=> Block2X <= x25(1);
							when "0010"=> Block2X <= x25(2);
							when "0011"=> Block2X <= x25(3);
							when "0100"=> Block2X <= x25(4);
							when "0101"=> Block2X <= x25(5);
							when "0110"=> Block2X <= x25(6);
							when "0111"=> Block2X <= x25(7);
							when "1000"=> Block2X <= x25(8);
							when "1001"=> Block2X <= x25(9);
							when "1010"=> Block2X <= x25(10);
							when "1011"=> Block2X <= x25(11);
							when "1100"=> Block2X <= x25(12);
							when others => Block2X <= x25(0);
						end case;
						case rand(11 downto 9) is
							when "000"=> Block3X <= x50(0);
							when "001"=> Block3X <= x50(1);
							when "010"=> Block3X <= x50(2);
							when "011"=> Block3X <= x50(3);
							when "100"=> Block3X <= x50(4);
							when "101"=> Block3X <= x50(5);
							when "110"=> Block3X <= x50(6);
							when others => Block3X <= x50(0);
						end case;
						case rand(13 downto 11) is
							when "000"=> Block4X <= x50(0);
							when "001"=> Block4X <= x50(1);
							when "010"=> Block4X <= x50(2);
							when "011"=> Block4X <= x50(3);
							when "100"=> Block4X <= x50(4);
							when "101"=> Block4X <= x50(5);
							when "110"=> Block4X <= x50(6);
							when others => Block4X <= x50(0);
						end case;
						case rand(15 downto 13) is
							when "000"=> Block5X <= x50(0);
							when "001"=> Block5X <= x50(1);
							when "010"=> Block5X <= x50(2);
							when "011"=> Block5X <= x50(3);
							when "100"=> Block5X <= x50(4);
							when "101"=> Block5X <= x50(5);
							when "110"=> Block5X <= x50(6);
							when others => Block5X <= x50(0);
						end case;
					end if;
				when weit =>
					if key(0) = '0' or key(1) = '0' then
						p_s <= game;
						aimode <= '0';
						templed <= "11111111";
						temptempled <= "11111111";
					end if;
					if key(3) = '0' then
						p_s <= game;
						aimode <= '1';
						templed <= "10000000";
					end if;
				when game =>
					if SW(0) = '0' and SW(1) = '0' then
						timercounter <= timercounter + 1;
						gamecounter <= gamecounter + 1;
						if aimode = '0' then
							if point < 10 then
								sevens1 <= "11000000";
								sevens2 <= sevensegment(point);
							else
								sevens1 <= sevensegment(point / 10);
								sevens2 <= sevensegment(point mod 10);
							end if;
							sevens3 <= sevensegment(timer1);
							sevens4 <= sevensegment(timer0);
							if timercounter = 24000000 then
								if SW(7) = '0' then
									speedtimer <= speedtimer + 1;
								end if;
								maintimer <= maintimer + 1;
								timer0 <= timer0 + 1;
								if timer0 = 9 then
									timer1 <= timer1 + 1;
									timer0 <= 0;
								end if;
								if speedtimer = 14 then
									tempspeed <= tempspeed - 50000;
									speedtimer <= 0;
								end if;
							end if;
							if SW(7) = '0' then
								gamespeed <= tempspeed;
							elsif SW(7) = '1' then
								gamespeed <= 75000;
							end if;
						elsif aimode = '1' then
							sevens1 <= "11111111";
							if timercounter <= 12000000 then 
								sevens2 <= "10001000";
								sevens3 <= "11110000";
							else
								sevens2 <= "11111111";
								sevens3 <= "11111111";
							end if;
							sevens4 <= "11111111";
							if timercounter = 12000000 then
								templed <= templed(0) & templed(7 downto 1);
							end if;
							gamespeed <= 100000;
						end if;
						if gamecounter = gamespeed then
							gamecounter <= 0;
							if pushdown < 300 then
								pushdown <= pushdown + 1;
							end if;
							Block0Y <= Block0Y + 1;
							if Block0Y = PlayerY then
								point <= point + 1;
							end if;
							if Block0Y = "0111100000" then
								Block0Y <= (others => '0');
								case rand(3 downto 0) is
									when "0000"=> Block0X <= x25(0);
									when "0001"=> Block0X <= x25(1);
									when "0010"=> Block0X <= x25(2);
									when "0011"=> Block0X <= x25(3);
									when "0100"=> Block0X <= x25(4);
									when "0101"=> Block0X <= x25(5);
									when "0110"=> Block0X <= x25(6);
									when "0111"=> Block0X <= x25(7);
									when "1000"=> Block0X <= x25(8);
									when "1001"=> Block0X <= x25(9);
									when "1010"=> Block0X <= x25(10);
									when "1011"=> Block0X <= x25(11);
									when "1100"=> Block0X <= x25(12);
									when others => Block0X <= x25(0);
								end case;
							end if;
							Block1Y <= Block1Y + 1;
							if Block1Y = PlayerY then
								point <= point + 1;
							end if;
							if Block1Y = "0111100000" then
								Block1Y <= (others => '0');
								case rand(6 downto 3) is
									when "0000"=> Block1X <= x25(0);
									when "0001"=> Block1X <= x25(1);
									when "0010"=> Block1X <= x25(2);
									when "0011"=> Block1X <= x25(3);
									when "0100"=> Block1X <= x25(4);
									when "0101"=> Block1X <= x25(5);
									when "0110"=> Block1X <= x25(6);
									when "0111"=> Block1X <= x25(7);
									when "1000"=> Block1X <= x25(8);
									when "1001"=> Block1X <= x25(9);
									when "1010"=> Block1X <= x25(10);
									when "1011"=> Block1X <= x25(11);
									when "1100"=> Block1X <= x25(12);
									when others => Block1X <= x25(0);
								end case;
							end if;
							Block2Y <= Block2Y + 1;
							if Block2Y = PlayerY then
								point <= point + 1;
							end if;
							if Block2Y = "0111100000" then
								Block2Y <= (others => '0');
								case rand(9 downto 6) is
									when "0000"=> Block2X <= x25(0);
									when "0001"=> Block2X <= x25(1);
									when "0010"=> Block2X <= x25(2);
									when "0011"=> Block2X <= x25(3);
									when "0100"=> Block2X <= x25(4);
									when "0101"=> Block2X <= x25(5);
									when "0110"=> Block2X <= x25(6);
									when "0111"=> Block2X <= x25(7);
									when "1000"=> Block2X <= x25(8);
									when "1001"=> Block2X <= x25(9);
									when "1010"=> Block2X <= x25(10);
									when "1011"=> Block2X <= x25(11);
									when "1100"=> Block2X <= x25(12);
									when others => Block2X <= x25(0);
								end case;
							end if;
							Block3Y <= Block3Y + 1;
							if Block3Y = PlayerY then
								point <= point + 1;
							end if;
							if Block3Y = "0111100000" then
								Block3Y <= (others => '0');
								case rand(11 downto 9) is
									when "000"=> Block3X <= x50(0);
									when "001"=> Block3X <= x50(1);
									when "010"=> Block3X <= x50(2);
									when "011"=> Block3X <= x50(3);
									when "100"=> Block3X <= x50(4);
									when "101"=> Block3X <= x50(5);
									when "110"=> Block3X <= x50(6);
									when others => Block3X <= x50(0);
								end case;
							end if;
							Block4Y <= Block4Y + 1;
							if Block4Y = PlayerY then
								point <= point + 1;
							end if;
							if Block4Y = "0111100000" then
								Block4Y <= (others => '0');
								case rand(13 downto 11) is
									when "000"=> Block4X <= x50(0);
									when "001"=> Block4X <= x50(1);
									when "010"=> Block4X <= x50(2);
									when "011"=> Block4X <= x50(3);
									when "100"=> Block4X <= x50(4);
									when "101"=> Block4X <= x50(5);
									when "110"=> Block4X <= x50(6);
									when others => Block4X <= x50(0);
								end case;
							end if;
							Block5Y <= Block5Y + 1;
							if Block5Y = PlayerY then
								point <= point + 1;
							end if;
							if Block5Y = "0111100000" then
								Block5Y <= (others => '0');
								case rand(15 downto 13) is
									when "000"=> Block5X <= x50(0);
									when "001"=> Block5X <= x50(1);
									when "010"=> Block5X <= x50(2);
									when "011"=> Block5X <= x50(3);
									when "100"=> Block5X <= x50(4);
									when "101"=> Block5X <= x50(5);
									when "110"=> Block5X <= x50(6);
									when others => Block5X <= x50(0);
								end case;
							end if;
						end if;
						if (Block0Y+Block0Height >= BulletY(0) and Block0Y <= BulletY(0)+BulletWidth and Block0X+Block0Width >= BulletX(0) and Block0X <= BulletX(0)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(1) and Block0Y <= BulletY(1)+BulletWidth and Block0X+Block0Width >= BulletX(1) and Block0X <= BulletX(1)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(2) and Block0Y <= BulletY(2)+BulletWidth and Block0X+Block0Width >= BulletX(2) and Block0X <= BulletX(2)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(3) and Block0Y <= BulletY(3)+BulletWidth and Block0X+Block0Width >= BulletX(3) and Block0X <= BulletX(3)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(4) and Block0Y <= BulletY(4)+BulletWidth and Block0X+Block0Width >= BulletX(4) and Block0X <= BulletX(4)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(5) and Block0Y <= BulletY(5)+BulletWidth and Block0X+Block0Width >= BulletX(5) and Block0X <= BulletX(5)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(6) and Block0Y <= BulletY(6)+BulletWidth and Block0X+Block0Width >= BulletX(6) and Block0X <= BulletX(6)+BulletWidth) or
							(Block0Y+Block0Height >= BulletY(7) and Block0Y <= BulletY(7)+BulletWidth and Block0X+Block0Width >= BulletX(7) and Block0X <= BulletX(7)+BulletWidth) then
							point <= point + 1;
							Block0Y <= (others => '0');
							case rand(3 downto 0) is
								when "0000"=> Block0X <= x25(0);
								when "0001"=> Block0X <= x25(1);
								when "0010"=> Block0X <= x25(2);
								when "0011"=> Block0X <= x25(3);
								when "0100"=> Block0X <= x25(4);
								when "0101"=> Block0X <= x25(5);
								when "0110"=> Block0X <= x25(6);
								when "0111"=> Block0X <= x25(7);
								when "1000"=> Block0X <= x25(8);
								when "1001"=> Block0X <= x25(9);
								when "1010"=> Block0X <= x25(10);
								when "1011"=> Block0X <= x25(11);
								when "1100"=> Block0X <= x25(12);
								when others => Block0X <= x25(0);
							end case;
						end if;
						if (Block1Y+Block1Height >= BulletY(0) and Block1Y <= BulletY(0)+BulletWidth and Block1X+Block1Width >= BulletX(0) and Block1X <= BulletX(0)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(1) and Block1Y <= BulletY(1)+BulletWidth and Block1X+Block1Width >= BulletX(1) and Block1X <= BulletX(1)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(2) and Block1Y <= BulletY(2)+BulletWidth and Block1X+Block1Width >= BulletX(2) and Block1X <= BulletX(2)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(3) and Block1Y <= BulletY(3)+BulletWidth and Block1X+Block1Width >= BulletX(3) and Block1X <= BulletX(3)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(4) and Block1Y <= BulletY(4)+BulletWidth and Block1X+Block1Width >= BulletX(4) and Block1X <= BulletX(4)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(5) and Block1Y <= BulletY(5)+BulletWidth and Block1X+Block1Width >= BulletX(5) and Block1X <= BulletX(5)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(6) and Block1Y <= BulletY(6)+BulletWidth and Block1X+Block1Width >= BulletX(6) and Block1X <= BulletX(6)+BulletWidth) or
							(Block1Y+Block1Height >= BulletY(7) and Block1Y <= BulletY(7)+BulletWidth and Block1X+Block1Width >= BulletX(7) and Block1X <= BulletX(7)+BulletWidth) then
							point <= point + 1;
							Block1Y <= (others => '0');
							case rand(6 downto 3) is
								when "0000"=> Block1X <= x25(0);
								when "0001"=> Block1X <= x25(1);
								when "0010"=> Block1X <= x25(2);
								when "0011"=> Block1X <= x25(3);
								when "0100"=> Block1X <= x25(4);
								when "0101"=> Block1X <= x25(5);
								when "0110"=> Block1X <= x25(6);
								when "0111"=> Block1X <= x25(7);
								when "1000"=> Block1X <= x25(8);
								when "1001"=> Block1X <= x25(9);
								when "1010"=> Block1X <= x25(10);
								when "1011"=> Block1X <= x25(11);
								when "1100"=> Block1X <= x25(12);
								when others => Block1X <= x25(0);
							end case;
						end if;
						if (Block2Y+Block2Height >= BulletY(0) and Block2Y <= BulletY(0)+BulletWidth and Block2X+Block2Width >= BulletX(0) and Block2X <= BulletX(0)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(1) and Block2Y <= BulletY(1)+BulletWidth and Block2X+Block2Width >= BulletX(1) and Block2X <= BulletX(1)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(2) and Block2Y <= BulletY(2)+BulletWidth and Block2X+Block2Width >= BulletX(2) and Block2X <= BulletX(2)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(3) and Block2Y <= BulletY(3)+BulletWidth and Block2X+Block2Width >= BulletX(3) and Block2X <= BulletX(3)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(4) and Block2Y <= BulletY(4)+BulletWidth and Block2X+Block2Width >= BulletX(4) and Block2X <= BulletX(4)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(5) and Block2Y <= BulletY(5)+BulletWidth and Block2X+Block2Width >= BulletX(5) and Block2X <= BulletX(5)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(6) and Block2Y <= BulletY(6)+BulletWidth and Block2X+Block2Width >= BulletX(6) and Block2X <= BulletX(6)+BulletWidth) or
							(Block2Y+Block2Height >= BulletY(7) and Block2Y <= BulletY(7)+BulletWidth and Block2X+Block2Width >= BulletX(7) and Block2X <= BulletX(7)+BulletWidth) then
							point <= point + 1;
							Block2Y <= (others => '0');
							case rand(9 downto 6)is
								when "0000"=> Block2X <= x25(0);
								when "0001"=> Block2X <= x25(1);
								when "0010"=> Block2X <= x25(2);
								when "0011"=> Block2X <= x25(3);
								when "0100"=> Block2X <= x25(4);
								when "0101"=> Block2X <= x25(5);
								when "0110"=> Block2X <= x25(6);
								when "0111"=> Block2X <= x25(7);
								when "1000"=> Block2X <= x25(8);
								when "1001"=> Block2X <= x25(9);
								when "1010"=> Block2X <= x25(10);
								when "1011"=> Block2X <= x25(11);
								when "1100"=> Block2X <= x25(12);
								when others => Block2X <= x25(0);
							end case;
						end if;
						if (Block3Y+Block3Height >= BulletY(0) and Block3Y <= BulletY(0)+BulletWidth and Block3X+Block3Width >= BulletX(0) and Block3X <= BulletX(0)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(1) and Block3Y <= BulletY(1)+BulletWidth and Block3X+Block3Width >= BulletX(1) and Block3X <= BulletX(1)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(2) and Block3Y <= BulletY(2)+BulletWidth and Block3X+Block3Width >= BulletX(2) and Block3X <= BulletX(2)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(3) and Block3Y <= BulletY(3)+BulletWidth and Block3X+Block3Width >= BulletX(3) and Block3X <= BulletX(3)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(4) and Block3Y <= BulletY(4)+BulletWidth and Block3X+Block3Width >= BulletX(4) and Block3X <= BulletX(4)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(5) and Block3Y <= BulletY(5)+BulletWidth and Block3X+Block3Width >= BulletX(5) and Block3X <= BulletX(5)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(6) and Block3Y <= BulletY(6)+BulletWidth and Block3X+Block3Width >= BulletX(6) and Block3X <= BulletX(6)+BulletWidth) or
							(Block3Y+Block3Height >= BulletY(7) and Block3Y <= BulletY(7)+BulletWidth and Block3X+Block3Width >= BulletX(7) and Block3X <= BulletX(7)+BulletWidth) then
							point <= point + 1;
							Block3Y <= (others => '0');
							case rand(11 downto 9) is
								when "000"=> Block3X <= x50(0);
								when "001"=> Block3X <= x50(1);
								when "010"=> Block3X <= x50(2);
								when "011"=> Block3X <= x50(3);
								when "100"=> Block3X <= x50(4);
								when "101"=> Block3X <= x50(5);
								when "110"=> Block3X <= x50(6);
								when others => Block3X <= x50(0);
							end case;
						end if;
						if (Block4Y+Block4Height >= BulletY(0) and Block4Y <= BulletY(0)+BulletWidth and Block4X+Block4Width >= BulletX(0) and Block4X <= BulletX(0)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(1) and Block4Y <= BulletY(1)+BulletWidth and Block4X+Block4Width >= BulletX(1) and Block4X <= BulletX(1)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(2) and Block4Y <= BulletY(2)+BulletWidth and Block4X+Block4Width >= BulletX(2) and Block4X <= BulletX(2)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(3) and Block4Y <= BulletY(3)+BulletWidth and Block4X+Block4Width >= BulletX(3) and Block4X <= BulletX(3)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(4) and Block4Y <= BulletY(4)+BulletWidth and Block4X+Block4Width >= BulletX(4) and Block4X <= BulletX(4)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(5) and Block4Y <= BulletY(5)+BulletWidth and Block4X+Block4Width >= BulletX(5) and Block4X <= BulletX(5)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(6) and Block4Y <= BulletY(6)+BulletWidth and Block4X+Block4Width >= BulletX(6) and Block4X <= BulletX(6)+BulletWidth) or
							(Block4Y+Block4Height >= BulletY(7) and Block4Y <= BulletY(7)+BulletWidth and Block4X+Block4Width >= BulletX(7) and Block4X <= BulletX(7)+BulletWidth) then
							point <= point + 1;
							Block4Y <= (others => '0');
							case rand(13 downto 11) is
								when "000"=> Block4X <= x50(0);
								when "001"=> Block4X <= x50(1);
								when "010"=> Block4X <= x50(2);
								when "011"=> Block4X <= x50(3);
								when "100"=> Block4X <= x50(4);
								when "101"=> Block4X <= x50(5);
								when "110"=> Block4X <= x50(6);
								when others => Block4X <= x50(0);
							end case;
						end if;
						if (Block5Y+Block5Height >= BulletY(0) and Block5Y <= BulletY(0)+BulletWidth and Block5X+Block5Width >= BulletX(0) and Block5X <= BulletX(0)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(1) and Block5Y <= BulletY(1)+BulletWidth and Block5X+Block5Width >= BulletX(1) and Block5X <= BulletX(1)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(2) and Block5Y <= BulletY(2)+BulletWidth and Block5X+Block5Width >= BulletX(2) and Block5X <= BulletX(2)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(3) and Block5Y <= BulletY(3)+BulletWidth and Block5X+Block5Width >= BulletX(3) and Block5X <= BulletX(3)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(4) and Block5Y <= BulletY(4)+BulletWidth and Block5X+Block5Width >= BulletX(4) and Block5X <= BulletX(4)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(5) and Block5Y <= BulletY(5)+BulletWidth and Block5X+Block5Width >= BulletX(5) and Block5X <= BulletX(5)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(6) and Block5Y <= BulletY(6)+BulletWidth and Block5X+Block5Width >= BulletX(6) and Block5X <= BulletX(6)+BulletWidth) or
							(Block5Y+Block5Height >= BulletY(7) and Block5Y <= BulletY(7)+BulletWidth and Block5X+Block5Width >= BulletX(7) and Block5X <= BulletX(7)+BulletWidth) then
							point <= point + 1;
							Block5Y <= (others => '0');
							case rand(15 downto 13) is
								when "000"=> Block5X <= x50(0);
								when "001"=> Block5X <= x50(1);
								when "010"=> Block5X <= x50(2);
								when "011"=> Block5X <= x50(3);
								when "100"=> Block5X <= x50(4);
								when "101"=> Block5X <= x50(5);
								when "110"=> Block5X <= x50(6);
								when others => Block5X <= x50(0);
							end case;
						end if;
						if bulletcounter = 3000000 and key(2) = '0' and bulletindex /= 8 and p_s = game and aimode = '0' then				
							templed <= temptempled(6 downto 0) & '0';
						end if;
						if key(2) = '1' then
							temptempled <= templed;
						end if;
						if PlayerX < "0010010110" or
							PlayerX > "0111100000" or
							(Block0Y+Block0Height >= PlayerY and Block0Y <= PlayerY+SquareWidth and Block0X+Block0Width >= PlayerX and Block0X <= PlayerX+SquareWidth) or
							(Block1Y+Block1Height >= PlayerY and Block1Y <= PlayerY+SquareWidth and Block1X+Block1Width >= PlayerX and Block1X <= PlayerX+SquareWidth) or												  
							(Block2Y+Block2Height >= PlayerY and Block2Y <= PlayerY+SquareWidth and Block2X+Block2Width >= PlayerX and Block2X <= PlayerX+SquareWidth) or
							(Block3Y+Block3Height >= PlayerY and Block3Y <= PlayerY+SquareWidth and Block3X+Block3Width >= PlayerX and Block3X <= PlayerX+SquareWidth) or	
							(Block4Y+Block4Height >= PlayerY and Block4Y <= PlayerY+SquareWidth and Block4X+Block4Width >= PlayerX and Block4X <= PlayerX+SquareWidth) or	
							(Block5Y+Block5Height >= PlayerY and Block5Y <= PlayerY+SquareWidth and Block5X+Block5Width >= PlayerX and Block5X <= PlayerX+SquareWidth)							
						then p_s <= endgame;
						end if;
						if point = 99 or maintimer = 99 then
							p_s <= endgame;
							finalstate <= '1';
						end if;
					end if;
				when endgame =>
					dancecounter <= dancecounter + 1;
					if dancecounter <= 12000000 then
						templed <= (others => '1');
						if finalstate = '0' then
							sevens1 <= "11000111";
							sevens2 <= "11000000";
							sevens3 <= "10010010";
							sevens4 <= "10000110";
						elsif finalstate = '1' then
							sevens1 <= "10011001";
							sevens2 <= "10001000";
							sevens3 <= "10001011";
							sevens4 <= "11000000";
						end if;
					elsif dancecounter > 12000000 and dancecounter <= 24000000 then
						templed <= (others => '0');
						sevens1 <= "01111111";
						sevens2 <= "01111111";
						sevens3 <= "01111111";
						sevens4 <= "01111111";
					elsif dancecounter > 24000000 and dancecounter <= 36000000 then
						templed <= (others => '1');
						if finalstate = '0' then
							sevens1 <= "11000111";
							sevens2 <= "11000000";
							sevens3 <= "10010010";
							sevens4 <= "10000110";
						elsif finalstate = '1' then
							sevens1 <= "10011001";
							sevens2 <= "10001000";
							sevens3 <= "10001011";
							sevens4 <= "11000000";
						end if;
					elsif dancecounter > 36000000 and dancecounter <= 48000000 then
						templed <= (others => '0');
						sevens1 <= "01111111";
						sevens2 <= "01111111";
						sevens3 <= "01111111";
						sevens4 <= "01111111";
					elsif dancecounter > 48000000 and dancecounter <= 72000000 then
						templed <= (others => '1');
						if finalstate = '0' then
							sevens1 <= "11000111";
							sevens2 <= "11000000";
							sevens3 <= "10010010";
							sevens4 <= "10000110";
						elsif finalstate = '1' then
							sevens1 <= "10011001";
							sevens2 <= "10001000";
							sevens3 <= "10001011";
							sevens4 <= "11000000";
						end if;
					end if;
					if dancecounter >= 24000000 then
						Block0Y <= Block0Y + 1;
						if Block0Y = "0111100000" then
							Block0Y <= (others => '0');
							case rand(3 downto 0) is
								when "0000"=> Block0X <= x25(0);
								when "0001"=> Block0X <= x25(1);
								when "0010"=> Block0X <= x25(2);
								when "0011"=> Block0X <= x25(3);
								when "0100"=> Block0X <= x25(4);
								when "0101"=> Block0X <= x25(5);
								when "0110"=> Block0X <= x25(6);
								when "0111"=> Block0X <= x25(7);
								when "1000"=> Block0X <= x25(8);
								when "1001"=> Block0X <= x25(9);
								when "1010"=> Block0X <= x25(10);
								when "1011"=> Block0X <= x25(11);
								when "1100"=> Block0X <= x25(12);
								when others => Block0X <= x25(0);
							end case;
						end if;
						Block1Y <= Block1Y + 1;
						if Block1Y = "0111100000" then
							Block1Y <= (others => '0');
							case rand(6 downto 3) is
								when "0000"=> Block1X <= x25(0);
								when "0001"=> Block1X <= x25(1);
								when "0010"=> Block1X <= x25(2);
								when "0011"=> Block1X <= x25(3);
								when "0100"=> Block1X <= x25(4);
								when "0101"=> Block1X <= x25(5);
								when "0110"=> Block1X <= x25(6);
								when "0111"=> Block1X <= x25(7);
								when "1000"=> Block1X <= x25(8);
								when "1001"=> Block1X <= x25(9);
								when "1010"=> Block1X <= x25(10);
								when "1011"=> Block1X <= x25(11);
								when "1100"=> Block1X <= x25(12);
								when others => Block1X <= x25(0);
							end case;
						end if;
						Block2Y <= Block2Y + 1;
						if Block2Y = "0111100000" then
							Block2Y <= (others => '0');
							case rand(9 downto 6) is
								when "0000"=> Block2X <= x25(0);
								when "0001"=> Block2X <= x25(1);
								when "0010"=> Block2X <= x25(2);
								when "0011"=> Block2X <= x25(3);
								when "0100"=> Block2X <= x25(4);
								when "0101"=> Block2X <= x25(5);
								when "0110"=> Block2X <= x25(6);
								when "0111"=> Block2X <= x25(7);
								when "1000"=> Block2X <= x25(8);
								when "1001"=> Block2X <= x25(9);
								when "1010"=> Block2X <= x25(10);
								when "1011"=> Block2X <= x25(11);
								when "1100"=> Block2X <= x25(12);
								when others => Block2X <= x25(0);
							end case;
						end if;
						Block3Y <= Block3Y + 1;
						if Block3Y = "0111100000" then
							Block3Y <= (others => '0');
							case rand(11 downto 9) is
								when "000"=> Block3X <= x50(0);
								when "001"=> Block3X <= x50(1);
								when "010"=> Block3X <= x50(2);
								when "011"=> Block3X <= x50(3);
								when "100"=> Block3X <= x50(4);
								when "101"=> Block3X <= x50(5);
								when "110"=> Block3X <= x50(6);
								when others => Block3X <= x50(0);
							end case;
						end if;
						Block4Y <= Block4Y + 1;
						if Block4Y = "0111100000" then
							Block4Y <= (others => '0');
							case rand(13 downto 11) is
								when "000"=> Block4X <= x50(0);
								when "001"=> Block4X <= x50(1);
								when "010"=> Block4X <= x50(2);
								when "011"=> Block4X <= x50(3);
								when "100"=> Block4X <= x50(4);
								when "101"=> Block4X <= x50(5);
								when "110"=> Block4X <= x50(6);
								when others => Block4X <= x50(0);
							end case;
						end if;
						Block5Y <= Block5Y + 1;
						if Block5Y = "0111100000" then
							Block5Y <= (others => '0');
							case rand(15 downto 13) is
								when "000"=> Block5X <= x50(0);
								when "001"=> Block5X <= x50(1);
								when "010"=> Block5X <= x50(2);
								when "011"=> Block5X <= x50(3);
								when "100"=> Block5X <= x50(4);
								when "101"=> Block5X <= x50(5);
								when "110"=> Block5X <= x50(6);
								when others => Block5X <= x50(0);
							end case;
						end if;
					end if;
					if dancecounter = 72000000 then
						p_s <= init;
						initcounter <= 24000000;
					end if;
			end case;
		end if;
	end process PrescalerCounter;
	
	process(CLK_24MHz, RESET)
	begin
		if RESET = '1' then
			playercounter <= 0;
			bulletcounter <= 0;
			bulletindex <= 0;
			bulletmovecounter <= 0;
			lookahead <= 320;
			safezone <= 320;
			PlayerX <= "0101000000";
			PlayerY <= "0101000000";
			BulletHoleX <= "0101001010";
			BulletHoleY <= "0101000000";
		elsif rising_edge(CLK_24MHz) then
			if p_s = init then
				bulletcounter <= 0;
				bulletindex <= 0;
				bulletmovecounter <= 0;
				lookahead <= 320;
				safezone <= 320;
				PlayerX <= "0101000000";
				PlayerY <= "0101000000";
				BulletHoleX <= "0101001010";
				BulletHoleY <= "0101000000";
			end if;
			bulletcounter <= bulletcounter + 1;
			bulletmovecounter <= bulletmovecounter + 1;
			playercounter <= playercounter + 1;
			aiplayercounter <= aiplayercounter + 1;
			lookaheadcounter <= lookaheadcounter + 1;
			if aimode = '1' then
				if lookaheadcounter = 10000 then
					if lookahead = Block0X and Block0Y = 260 then
						lookahead <= lookahead + 25;
					elsif lookahead = Block1X and Block1Y = 260 then
						lookahead <= lookahead + 25;
					elsif lookahead = Block2X and Block1Y = 260 then
						lookahead <= lookahead + 25;
					elsif lookahead = Block3X and Block1Y = 260 then
						lookahead <= lookahead + 50;
					elsif lookahead = Block4X and Block1Y = 260 then
						lookahead <= lookahead + 50;
					elsif lookahead = Block5X and Block1Y = 260 then
						lookahead <= lookahead + 50;
					else
						if (lookahead < Block0X and Block0X - lookahead <= 100 and lookahead + SquareWidth >= Block0X) or
							(lookahead < Block1X and Block1X - lookahead <= 100 and lookahead + SquareWidth >= Block1X) or
							(lookahead < Block2X and Block2X - lookahead <= 100 and lookahead + SquareWidth >= Block2X) or
							(lookahead < Block3X and Block3X - lookahead <= 100 and lookahead + SquareWidth >= Block3X) or
							(lookahead < Block4X and Block4X - lookahead <= 100 and lookahead + SquareWidth >= Block4X) or
							(lookahead < Block5X and Block5X - lookahead <= 100 and lookahead + SquareWidth >= Block5X) then
							safezone <= lookahead;
						else
							lookahead <= lookahead + 1;
						end if;
					end if;
				end if;
				if aiplayercounter > 90000 then
					aiplayercounter <= 0;
					if PlayerX = safezone and p_s /= endgame then
						PlayerX <= PlayerX;
					elsif PlayerX < safezone and p_s /= endgame then
						PlayerX <= PlayerX + 1;
						BulletHoleX <= BulletHoleX + 1;
					elsif PlayerX > safezone and p_s /= endgame then
						PlayerX <= PlayerX - 1;
						BulletHoleX <= BulletHoleX - 1;
					end if;
				end if;
			elsif aimode = '0' then
				if playercounter > 120000 then
					playercounter <= 0;
					if key(0) = '0' and p_s /= endgame and SW(0) = '0' then
						PlayerX <= PlayerX + 1;
						BulletHoleX <= BulletHoleX + 1;
					elsif key(1) = '0' and p_s /= endgame and SW(0) = '0' then
						PlayerX <= PlayerX - 1;
						BulletHoleX <= BulletHoleX - 1;
					end if;
				elsif bulletcounter = 3000000 then
					if key(2) = '0' and bulletindex /= 8 and p_s = game and SW(0) = '0' then
						BulletX(bulletindex) <= PlayerX + 10;
						BulletY(bulletindex) <= PlayerY;
						bulletindex <= bulletindex + 1;
					end if;
				end if;
			end if;
			if bulletindex = 8 then
				BulletHoleX <= (others => '1');
				BulletHoleY <= (others => '1');
			end if;
			if bulletmovecounter = 50000 then
				if BulletX(0) /= "0000000000" and BulletY(0) /= "0000000000" then
					BulletY(0) <= BulletY(0) - 1;
					if BulletY(0) = "0000000000" then
						BulletX(0) <= (others => '1');
					end if;
				end if;
				if BulletX(1) /= "0000000000" and BulletY(1) /= "0000000000" then
					BulletY(1) <= BulletY(1) - 1;
					if BulletY(1) = "0000000000" then
						BulletX(1) <= (others => '1');
					end if;
				end if;
				if BulletX(2) /= "0000000000" and BulletY(2) /= "0000000000" then
					BulletY(2) <= BulletY(2) - 1;
					if BulletY(2) = "0000000000" then
						BulletX(2) <= (others => '1');
					end if;
				end if;
				if BulletX(3) /= "0000000000" and BulletY(3) /= "0000000000" then
					BulletY(3) <= BulletY(3) - 1;
					if BulletY(3) = "0000000000" then
						BulletX(3) <= (others => '1');
					end if;
				end if;
				if BulletX(4) /= "0000000000" and BulletY(4) /= "0000000000" then
					BulletY(4) <= BulletY(4) - 1;
					if BulletY(4) = "0000000000" then
						BulletX(4) <= (others => '1');
					end if;
				end if;
				if BulletX(5) /= "0000000000" and BulletY(5) /= "0000000000" then
					BulletY(5) <= BulletY(5) - 1;
					if BulletY(5) = "0000000000" then
						BulletX(5) <= (others => '1');
					end if;
				end if;
				if BulletX(6) /= "0000000000" and BulletY(6) /= "0000000000" then
					BulletY(6) <= BulletY(6) - 1;
					if BulletY(6) = "0000000000" then
						BulletX(6) <= (others => '1');
					end if;
				end if;
				if BulletX(7) /= "0000000000" and BulletY(7) /= "0000000000" then
					BulletY(7) <= BulletY(7) - 1;
					if BulletY(7) = "0000000000" then
						BulletX(7) <= (others => '1');
					end if;
				end if;
			end if;
			if (Block0Y+Block0Height >= BulletY(0) and Block0Y <= BulletY(0)+BulletWidth and Block0X+Block0Width >= BulletX(0) and Block0X <= BulletX(0)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(0) and Block1Y <= BulletY(0)+BulletWidth and Block1X+Block1Width >= BulletX(0) and Block1X <= BulletX(0)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(0) and Block2Y <= BulletY(0)+BulletWidth and Block2X+Block2Width >= BulletX(0) and Block2X <= BulletX(0)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(0) and Block3Y <= BulletY(0)+BulletWidth and Block3X+Block3Width >= BulletX(0) and Block3X <= BulletX(0)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(0) and Block4Y <= BulletY(0)+BulletWidth and Block4X+Block4Width >= BulletX(0) and Block4X <= BulletX(0)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(0) and Block5Y <= BulletY(0)+BulletWidth and Block5X+Block5Width >= BulletX(0) and Block5X <= BulletX(0)+BulletWidth) then
				BulletX(0) <= (others => '0');
				BulletY(0) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(1) and Block0Y <= BulletY(1)+BulletWidth and Block0X+Block0Width >= BulletX(1) and Block0X <= BulletX(1)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(1) and Block1Y <= BulletY(1)+BulletWidth and Block1X+Block1Width >= BulletX(1) and Block1X <= BulletX(1)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(1) and Block2Y <= BulletY(1)+BulletWidth and Block2X+Block2Width >= BulletX(1) and Block2X <= BulletX(1)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(1) and Block3Y <= BulletY(1)+BulletWidth and Block3X+Block3Width >= BulletX(1) and Block3X <= BulletX(1)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(1) and Block4Y <= BulletY(1)+BulletWidth and Block4X+Block4Width >= BulletX(1) and Block4X <= BulletX(1)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(1) and Block5Y <= BulletY(1)+BulletWidth and Block5X+Block5Width >= BulletX(1) and Block5X <= BulletX(1)+BulletWidth) then
				BulletX(1) <= (others => '0');
				BulletY(1) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(2) and Block0Y <= BulletY(2)+BulletWidth and Block0X+Block0Width >= BulletX(2) and Block0X <= BulletX(2)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(2) and Block1Y <= BulletY(2)+BulletWidth and Block1X+Block1Width >= BulletX(2) and Block1X <= BulletX(2)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(2) and Block2Y <= BulletY(2)+BulletWidth and Block2X+Block2Width >= BulletX(2) and Block2X <= BulletX(2)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(2) and Block3Y <= BulletY(2)+BulletWidth and Block3X+Block3Width >= BulletX(2) and Block3X <= BulletX(2)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(2) and Block4Y <= BulletY(2)+BulletWidth and Block4X+Block4Width >= BulletX(2) and Block4X <= BulletX(2)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(2) and Block5Y <= BulletY(2)+BulletWidth and Block5X+Block5Width >= BulletX(2) and Block5X <= BulletX(2)+BulletWidth) then
				BulletX(2) <= (others => '0');
				BulletY(2) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(3) and Block0Y <= BulletY(3)+BulletWidth and Block0X+Block0Width >= BulletX(3) and Block0X <= BulletX(3)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(3) and Block1Y <= BulletY(3)+BulletWidth and Block1X+Block1Width >= BulletX(3) and Block1X <= BulletX(3)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(3) and Block2Y <= BulletY(3)+BulletWidth and Block2X+Block2Width >= BulletX(3) and Block2X <= BulletX(3)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(3) and Block3Y <= BulletY(3)+BulletWidth and Block3X+Block3Width >= BulletX(3) and Block3X <= BulletX(3)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(3) and Block4Y <= BulletY(3)+BulletWidth and Block4X+Block4Width >= BulletX(3) and Block4X <= BulletX(3)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(3) and Block5Y <= BulletY(3)+BulletWidth and Block5X+Block5Width >= BulletX(3) and Block5X <= BulletX(3)+BulletWidth) then
				BulletX(3) <= (others => '0');
				BulletY(3) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(4) and Block0Y <= BulletY(4)+BulletWidth and Block0X+Block0Width >= BulletX(4) and Block0X <= BulletX(4)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(4) and Block1Y <= BulletY(4)+BulletWidth and Block1X+Block1Width >= BulletX(4) and Block1X <= BulletX(4)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(4) and Block2Y <= BulletY(4)+BulletWidth and Block2X+Block2Width >= BulletX(4) and Block2X <= BulletX(4)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(4) and Block3Y <= BulletY(4)+BulletWidth and Block3X+Block3Width >= BulletX(4) and Block3X <= BulletX(4)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(4) and Block4Y <= BulletY(4)+BulletWidth and Block4X+Block4Width >= BulletX(4) and Block4X <= BulletX(4)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(4) and Block5Y <= BulletY(4)+BulletWidth and Block5X+Block5Width >= BulletX(4) and Block5X <= BulletX(4)+BulletWidth) then
				BulletX(4) <= (others => '0');
				BulletY(4) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(5) and Block0Y <= BulletY(5)+BulletWidth and Block0X+Block0Width >= BulletX(5) and Block0X <= BulletX(5)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(5) and Block1Y <= BulletY(5)+BulletWidth and Block1X+Block1Width >= BulletX(5) and Block1X <= BulletX(5)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(5) and Block2Y <= BulletY(5)+BulletWidth and Block2X+Block2Width >= BulletX(5) and Block2X <= BulletX(5)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(5) and Block3Y <= BulletY(5)+BulletWidth and Block3X+Block3Width >= BulletX(5) and Block3X <= BulletX(5)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(5) and Block4Y <= BulletY(5)+BulletWidth and Block4X+Block4Width >= BulletX(5) and Block4X <= BulletX(5)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(5) and Block5Y <= BulletY(5)+BulletWidth and Block5X+Block5Width >= BulletX(5) and Block5X <= BulletX(5)+BulletWidth) then
				BulletX(5) <= (others => '0');
				BulletY(5) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(6) and Block0Y <= BulletY(6)+BulletWidth and Block0X+Block0Width >= BulletX(6) and Block0X <= BulletX(6)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(6) and Block1Y <= BulletY(6)+BulletWidth and Block1X+Block0Width >= BulletX(6) and Block1X <= BulletX(6)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(6) and Block2Y <= BulletY(6)+BulletWidth and Block2X+Block0Width >= BulletX(6) and Block2X <= BulletX(6)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(6) and Block3Y <= BulletY(6)+BulletWidth and Block3X+Block0Width >= BulletX(6) and Block3X <= BulletX(6)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(6) and Block4Y <= BulletY(6)+BulletWidth and Block4X+Block0Width >= BulletX(6) and Block4X <= BulletX(6)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(6) and Block5Y <= BulletY(6)+BulletWidth and Block5X+Block0Width >= BulletX(6) and Block5X <= BulletX(6)+BulletWidth) then
				BulletX(6) <= (others => '0');
				BulletY(6) <= (others => '0');
			end if;
			if (Block0Y+Block0Height >= BulletY(7) and Block0Y <= BulletY(7)+BulletWidth and Block0X+Block0Width >= BulletX(7) and Block0X <= BulletX(7)+BulletWidth) or
				(Block1Y+Block1Height >= BulletY(7) and Block1Y <= BulletY(7)+BulletWidth and Block1X+Block1Width >= BulletX(7) and Block1X <= BulletX(7)+BulletWidth) or
				(Block2Y+Block2Height >= BulletY(7) and Block2Y <= BulletY(7)+BulletWidth and Block2X+Block2Width >= BulletX(7) and Block2X <= BulletX(7)+BulletWidth) or
				(Block3Y+Block3Height >= BulletY(7) and Block3Y <= BulletY(7)+BulletWidth and Block3X+Block3Width >= BulletX(7) and Block3X <= BulletX(7)+BulletWidth) or
				(Block4Y+Block4Height >= BulletY(7) and Block4Y <= BulletY(7)+BulletWidth and Block4X+Block4Width >= BulletX(7) and Block4X <= BulletX(7)+BulletWidth) or
				(Block5Y+Block5Height >= BulletY(7) and Block5Y <= BulletY(7)+BulletWidth and Block5X+Block5Width >= BulletX(7) and Block5X <= BulletX(7)+BulletWidth) then
				BulletX(7) <= (others => '0');
				BulletY(7) <= (others => '0');
			end if;
		end if;
	end process;
	
	process(CLK_24MHz)
	begin
		if rising_edge(CLK_24MHz) then
			sscounter <= sscounter + 1;
			if sscounter = 20000 then
				EN <= "1110";
				sevenseg <= sevens1;
			elsif sscounter = 40000 then
				EN <= "1101";
				sevenseg <= sevens2;
			elsif sscounter = 60000 then
				EN <= "1011";
				sevenseg <= sevens3;
			elsif sscounter = 80000 then
				EN <= "0111";
				sevenseg <= sevens4;
			end if;
	end if;
	end process;

	ColorOutput <=	   "000000" when (ScanlineX >= BulletHoleX AND ScanlineY >= BulletHoleY AND ScanlineX < BulletHoleX+BulletWidth AND ScanlineY < BulletHoleY+BulletWidth)
					or (ScanlineX >= BulletX(0) AND ScanlineY >= BulletY(0) AND ScanlineX < BulletX(0)+BulletWidth AND ScanlineY < BulletY(0)+BulletWidth)
					or (ScanlineX >= BulletX(1) AND ScanlineY >= BulletY(1) AND ScanlineX < BulletX(1)+BulletWidth AND ScanlineY < BulletY(1)+BulletWidth)
					or (ScanlineX >= BulletX(2) AND ScanlineY >= BulletY(2) AND ScanlineX < BulletX(2)+BulletWidth AND ScanlineY < BulletY(2)+BulletWidth)
					or (ScanlineX >= BulletX(3) AND ScanlineY >= BulletY(3) AND ScanlineX < BulletX(3)+BulletWidth AND ScanlineY < BulletY(3)+BulletWidth)
					or (ScanlineX >= BulletX(4) AND ScanlineY >= BulletY(4) AND ScanlineX < BulletX(4)+BulletWidth AND ScanlineY < BulletY(4)+BulletWidth)
					or (ScanlineX >= BulletX(5) AND ScanlineY >= BulletY(5) AND ScanlineX < BulletX(5)+BulletWidth AND ScanlineY < BulletY(5)+BulletWidth)
					or (ScanlineX >= BulletX(6) AND ScanlineY >= BulletY(6) AND ScanlineX < BulletX(6)+BulletWidth AND ScanlineY < BulletY(6)+BulletWidth)
					or (ScanlineX >= BulletX(7) AND ScanlineY >= BulletY(7) AND ScanlineX < BulletX(7)+BulletWidth AND ScanlineY < BulletY(7)+BulletWidth)
					else  "111100" when ScanlineX >= PlayerX AND ScanlineY >= PlayerY AND ScanlineX < PlayerX+SquareWidth AND ScanlineY < PlayerY+SquareWidth 
					else  "001100" when (ScanlineX>0 and ScanlineX<150) 
					or (ScanlineX<640 and ScanlineX>500)
               or (	ScanlineY >250+pushdown and ScanlineY<400+pushdown and ScanlineY+100> Scanlinex+250+pushdown)	
              	or ( 	ScanlineY>250+pushdown and ScanlineY<400+pushdown and  ScanlineY -250-pushdown >560-ScanlineX)
               or (	ScanlineX>144 and	ScanlineX< 250 and  pushdown+400<Scanliney+1)
               or ( ScanlineX >410 and ScanlineX-2 <500 and ScanlineY+2>400+pushdown)	
					else  "110000" when (ScanlineX >= Block0X AND ScanlineY >= Block0Y AND ScanlineX < Block0X+Block0Width AND ScanlineY < Block0Y+Block0Height)
					or (ScanlineX >= Block1X AND ScanlineY >= Block1Y AND ScanlineX < Block1X+Block1Width AND ScanlineY < Block1Y+Block1Height)
					or (ScanlineX >= Block2X AND ScanlineY >= Block2Y AND ScanlineX < Block2X+Block2Width AND ScanlineY < Block2Y+Block2Height)
					or (ScanlineX >= Block3X AND ScanlineY >= Block3Y AND ScanlineX < Block3X+Block3Width AND ScanlineY < Block3Y+Block3Height)
					or (ScanlineX >= Block4X AND ScanlineY >= Block4Y AND ScanlineX < Block4X+Block4Width AND ScanlineY < Block4Y+Block4Height)
					or (ScanlineX >= Block5X AND ScanlineY >= Block5Y AND ScanlineX < Block5X+Block5Width AND ScanlineY < Block5Y+Block5Height)
					else	"000011";

	ColorOut <= ColorOutput;
	LED <= templed;
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
end Behavioral;

