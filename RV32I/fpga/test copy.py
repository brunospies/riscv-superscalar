import serial
import struct
import time
import os

# ================= Configurações =================
PORTA = '/dev/ttyUSB0'  # Ajuste para a sua porta (ex: 'COM3' no Windows)
BAUD_RATE = 115200

# Ficheiros com o código Assembly compilado / Dados
ARQUIVO_INSTRUCOES = 'instrucoes.txt'
ARQUIVO_DADOS = 'dados.txt'
# =================================================

def parse_e_enviar(caminho_arquivo, conexao_serial):
    """
    Lê um ficheiro txt, extrai o endereço e o dado (ignorando o assembly),
    e envia via UART usando o protocolo do bootloader (espera por ACK).
    """
    if not os.path.exists(caminho_arquivo):
        print(f"[AVISO] Ficheiro '{caminho_arquivo}' não encontrado. Saltando...")
        return True

    print(f"\n--- Processando ficheiro: {caminho_arquivo} ---")
    
    with open(caminho_arquivo, 'r') as f:
        linhas = f.readlines()

    linhas_enviadas = 0

    for numero_linha, linha in enumerate(linhas, 1):
        linha = linha.strip()
        
        # Ignora linhas vazias ou o cabeçalho
        if not linha or not linha.startswith("0x"):
            continue

        partes = linha.split()
        endereco_str = partes[0]
        dado_str = partes[1]

        try:
            endereco_int = int(endereco_str, 16)
            dado_int = int(dado_str, 16)
            
            # PASSO 1: Empacota para binário de 32 bits (Little-Endian)
            pacote_endereco = struct.pack('<I', endereco_int)
            pacote_dado = struct.pack('<I', dado_int)
            
            # PASSO 2: Envia para o FPGA
            conexao_serial.write(pacote_endereco)
            conexao_serial.write(pacote_dado)
            conexao_serial.flush()
            
            # PASSO 3: Espera pelo ACK ('0x01')
            ack = conexao_serial.read(1)
            
            if ack == b'\x01':
                print(f"[OK] Endereço: {endereco_str} | Escrito: {dado_str}")
                linhas_enviadas += 1
            elif ack == b'':
                print(f"[ERRO] Timeout no endereço {endereco_str}! O FPGA não respondeu.")
                return False
            else:
                print(f"[ERRO] ACK inesperado ({ack}) no endereço {endereco_str}.")
                return False

        except ValueError:
            print(f"[ERRO FORMATO] Erro na linha {numero_linha}: '{linha}'")
            continue

    print(f"--- Concluído: {linhas_enviadas} palavras gravadas de {caminho_arquivo} ---")
    return True

# ================= Execução Principal =================
try:
    print(f"Abrindo conexão em {PORTA} a {BAUD_RATE} bps...")
    
    with serial.Serial(PORTA, BAUD_RATE, timeout=3) as ser:
        time.sleep(1) # Pausa para estabilizar a porta
        
        # 1. Fase de UPLOAD (Escrever no FPGA)
        sucesso_inst = parse_e_enviar(ARQUIVO_INSTRUCOES, ser)
        sucesso_dados = parse_e_enviar(ARQUIVO_DADOS, ser)
        
        # 2. Fase de MONITORAMENTO / DUMP DE MEMÓRIA (Ler do FPGA)
        if sucesso_inst and sucesso_dados:

            # Avisa o FPGA que terminou (Endereço 0xFFFFFFFF e Dado 0x00000000)
            ser.write(struct.pack('<I', 0xFFFFFFFF))
            ser.flush()

            print("\n" + "="*65)
            print("UPLOAD CONCLUÍDO COM SUCESSO!")
            print("Entrando em MODO DUMP DE MEMÓRIA (Pressione Ctrl+C para sair)")
            print("Inicie o sinal 'mem_scan' na sua placa FPGA agora...")
            print("="*65 + "\n")
            
            # Limpa qualquer "lixo" que tenha ficado no buffer
            ser.reset_input_buffer()
            
            # Assumimos que o scan do FPGA começa no endereço 0.
            # (Se o seu FPGA começar noutro endereço, altere o 0 abaixo)
            endereco_atual = 0
            
            while True:
                # Precisamos ler de 4 em 4 bytes (1 palavra de 32 bits)
                if ser.in_waiting >= 4:
                    
                    # Lê exatamente 4 bytes do buffer
                    pacote_bytes = ser.read(4)
                    
                    # Desempacota Little-Endian ('<') para Inteiro Unsigned 32-bits ('I')
                    valor_32bits = struct.unpack('<I', pacote_bytes)[0]
                    
                    # Imprime formatado (08X garante que o endereço e o Hex tenham 8 dígitos)
                    print(f"Endereço 0x{endereco_atual:08X} | Hex: 0x{valor_32bits:08X} | Dec: {valor_32bits}")
                    
                    # Avança o contador (Assumindo que a memória avança de 4 em 4)
                    endereco_atual += 4
                    
                time.sleep(0.001)

except serial.SerialException as e:
    print(f"\n[ERRO FATAL] Não foi possível abrir a porta serial: {e}")
except KeyboardInterrupt:
    print("\n\n[AVISO] Conexão encerrada pelo utilizador.")