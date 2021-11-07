library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.lzd_pkg;

entity testbench is
end testbench;

architecture beh of testbench is
    signal t_clk : std_logic := '1';
    signal t_rstn : std_logic := '0';
    signal t_en : std_logic := '0';
    
    signal t_dout : std_logic_vector(127 downto 0);
    signal t_din : std_logic_vector(95 downto 0);
    
    signal t_x_0 : signed(15 downto 0);
    signal t_x_1 : signed(15 downto 0);
    
    signal t_y_0 : signed(7 downto 0);
    signal t_y_1 : signed(7 downto 0);
    signal t_factor : signed(15 downto 0) := to_signed(256, 16);
    signal t_offset : signed(7 downto 0) := to_signed(2 * 4, 8);
    
    signal t_sb_data : std_logic;
    signal t_sb_en   : std_logic;
    -- signal t_sb_dout : std_logic_vector(23 downto 0);
    -- signal t_sb_updated : std_logic;
    
    -- signal t_axis_tready : std_logic;
    -- signal t_axis_tvalid : std_logic;
    -- signal t_axis_tdata  : std_logic_vector(127 downto 0);
    -- signal t_sub_en      : std_logic;
    
    -- signal t_p : unsigned(5 downto 0);
    -- 
    -- signal t_y_e : unsigned(26 downto 0);
    -- 
    -- signal t_y_sin : signed(17 downto 0);
    -- signal t_y_cos : signed(17 downto 0);
    -- 
    -- signal t_y : unsigned(16 downto 0);
    -- signal t_x_r : unsigned(18 downto 0);
    -- 
    -- signal t_x_trig : unsigned(13 downto 0);
    -- 
    -- 
    -- signal t_shift_c : signed(5 downto 0)               := to_signed(-16, 6);
    -- signal t_shift_dout : std_logic_vector(31 downto 0) := (others => '0');
    
    component boxmuller is
        port ( 
            clk  : in std_logic;
            rstn : in std_logic;
            en   : in std_logic;
            u    : in std_logic_vector(95 downto 0);
            x_0  : out signed(15 downto 0);
            x_1  : out signed(15 downto 0)
        );
    end component;
    
    component xoroshiro128plus is
    generic (
        seed_1 : unsigned(63 downto 0);
        seed_0 : unsigned(63 downto 0)
        );
    port (
        clk    : in  std_logic;
        rstn   : in  std_logic;
        enable : in  std_logic;
        dout   : out std_logic_vector(63 downto 0)
    );
    end component;
    
    component output_remapper is
        port (
            clk : in std_logic;
            rstn : in std_logic;
            en   : in std_logic;
            din    : in signed (15 downto 0); -- 5,11
            factor : in signed (15 downto 0); -- 8,8
            offset : in signed (7 downto 0);  -- 6,2
            dout   : out signed(7 downto 0)
        );
    end component;
    
    component sb_des is
        generic (
            DEPTH : integer := 24
        );
        port (
            clk     : in std_logic;
            rstn    : in std_logic;
            sb_data : in std_logic;
            sb_en   : in std_logic;
            dout    : out std_logic_vector(DEPTH - 1 downto 0);
            updated : out std_logic
        );
    end component;
    
    component bm_axis_gen is
        generic (
            COUNTER_WIDTH : integer := 6
        );
        port (
            clk             : in std_logic;
            rstn            : in std_logic;
            updated         : in std_logic;
            din             : in std_logic_vector(127 downto 0);
            s_axis_tready   : in std_logic;
            s_axis_tvalid   : out std_logic;
            s_axis_tdata    : out std_logic_vector(127 downto 0);
            sub_en          : out std_logic
        );
    end component bm_axis_gen;
    
    component grng_16 is
        generic (
            xoro_seed_base : integer := 0
            );
        port (
            clk     : in std_logic;
            resetn  : in std_logic;
            en      : in std_logic;
            
            s_axis_tdata    : out std_logic_vector(8 * 16 - 1 downto 0);
            s_axis_tready   : in std_logic;
            s_axis_tvalid   : out std_logic;
            
            sb_din  : in std_logic;
            sb_en   : in std_logic
        );
    end component grng_16;
    
begin

    t_din <= t_dout(t_din'range);

    -- t_din(95 downto 49) <= t_dout(95 downto 49);
    -- t_din(48 downto 24) <= (others => '0');
    -- t_din(23 downto 0) <= t_dout(23 downto 0);
    
    -- t_din(48 downto 1) <= std_logic_vector(to_unsigned(16#5d2b02#, 48));
    -- t_din(64 downto 49) <= std_logic_vector(to_unsigned(16#adbd#, 16));
    -- t_din(95 downto 65) <= std_logic_vector(to_unsigned(16#12d57bf1#, 31));
    
    rand_0 : xoroshiro128plus
        generic map (
            seed_1 => X"1976c51ab89a5886",
            seed_0 => X"86114fc94d6c4ad5"
            )
        port map (
            clk    => t_clk,
            rstn   => t_rstn,
            enable => t_en,
            dout   => t_dout(127 downto 64)
        );
    
    rand_1 : xoroshiro128plus
        generic map (
            seed_1 => X"e0296ce69151a79f",
            seed_0 => X"99ee2d06176445b6"
        )
        port map (
            clk    => t_clk,
            rstn   => t_rstn,
            enable => t_en,
            dout   => t_dout(63 downto 0)
        );
    
    bm : boxmuller
        port map ( 
            clk  => t_clk,
            rstn => t_rstn,
            en => t_en,
            u    => t_din,
            x_0  => t_x_0,
            x_1  => t_x_1
        );
    
    output_0 : output_remapper
        port map (
            clk     => t_clk,
            rstn    => t_rstn,
            en      => t_en,
            din     => t_x_0,
            factor  => t_factor,
            offset  => t_offset,
            dout    => t_y_0
        );
        
    output_1 : output_remapper
        port map (
            clk     => t_clk,
            rstn    => t_rstn,
            en      => t_en,
            din     => t_x_0,
            factor  => t_factor,
            offset  => to_signed(0, 8),
            dout    => t_y_1
        );
        
    -- sb : sb_des
    --     generic map (
    --         DEPTH => 24
    --     )
    --     port map (
    --         clk     => t_clk,
    --         rstn    => t_rstn,
    --         sb_data => t_sb_data,
    --         sb_en   => t_sb_en,
    --         dout    => t_sb_dout,
    --         updated => t_sb_updated
    --     );
        
    -- bm_axis : bm_axis_gen
    --     generic map (
    --         COUNTER_WIDTH => 6
    --     )
    --     port map (
    --         clk             => t_clk,
    --         rstn            => t_rstn,
    --         updated         => t_sb_updated,
    --         din             => t_dout,
    --         s_axis_tready   => t_axis_tready,
    --         s_axis_tvalid   => t_axis_tvalid,
    --         s_axis_tdata    => t_axis_tdata,
    --         sub_en          => t_sub_en
    --     );
        
    -- grng : grng_16
    --     generic map (
    --         xoro_seed_base => 0
    --         )
    --     port map (
    --         clk     => t_clk,
    --         resetn  => t_rstn,
    --         en      => t_en,
    --         
    --         s_axis_tdata    => t_axis_tdata,
    --         s_axis_tready   => t_axis_tready,
    --         s_axis_tvalid   => t_axis_tvalid,
    --         
    --         sb_din  => t_sb_data,
    --         sb_en   => t_sb_en
    --     );
    
    t_clk <= not t_clk after 5 ns;
    t_rstn <= '1' after 3 ns;
    
    seq : process
    begin
        -- t_axis_tready <= '0';
        t_sb_data <= '0';
        -- wait for 309 ns;
        wait for 11 ns;
        t_en <= '1';
        -- t_sb_en <= '1';
        
        -- wait for 70 ns;
        -- t_sb_data <= '1';
        -- wait for 10 ns;
        -- t_sb_data <= '0';
        -- 
        -- wait for 160 ns;
        -- t_sb_en <= '0';
        
        -- wait for 700 ns;
        -- t_axis_tready <= '1';
        -- wait for 50 ns;
        -- t_axis_tready <= '0';
        -- wait for 50 ns;
        -- t_axis_tready <= '1';
        
        -- wait for 50 ns;
        -- t_en <= '0';
        -- wait for 50 ns;
        -- t_en <= '1';
        
        -- wait for 10 ns;
        -- t_en <= '0';
        -- wait for 1 ns;
        -- wait for 10 us;
        -- t_en <= '0';
        -- wait for 50 ns;
        -- t_en <= '1';
        
        wait for 500 ms;
    --     t_din <= (47 => '1', others => '0');
    --     wait for 22 ns;
    --     
    --     for i in 0 to 47 loop
    --         t_din <= '0' & t_din(47 downto 1);
    --         wait for 10 ns;
    --     end loop;
    --     
    --     t_din <= (16 => '1', others => '0');
    --     wait for 10 ns;
    --     
    --     for i in 0 to 31 loop
    --         t_shift_c <= t_shift_c + 1;
    --         wait for 10 ns;
    --     end loop;
    --     
    --     t_din <= "100010111011100100001011001011010011001111100101";
    --     
    --     wait for 5 ms;
    end process seq;
    
end beh;
