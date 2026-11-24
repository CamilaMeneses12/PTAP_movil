import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { TIPOS_REGISTRO } from '../planta/parametro.entity.js';
import type { TipoRegistro } from '../planta/parametro.entity.js';
import { ESTADOS } from './registro.entity.js';
import type { Estado } from './registro.entity.js';

export class ValorDto {
  @ApiProperty({ example: 'ph_tratada' })
  @IsString()
  @Length(1, 40)
  parametro: string;

  @ApiProperty({ example: 7.2 })
  @IsNumber({ allowNaN: false, allowInfinity: false })
  valor: number;
}

// El autor no va en el cuerpo: sale del token. Nadie puede registrar a nombre de otro.
export class CrearRegistroDto {
  @ApiProperty({ enum: TIPOS_REGISTRO })
  @IsIn(TIPOS_REGISTRO, { message: `El tipo debe ser uno de: ${TIPOS_REGISTRO.join(', ')}` })
  tipo: TipoRegistro;

  @ApiProperty({ type: [ValorDto] })
  @IsArray()
  @ArrayMinSize(1, { message: 'El registro no tiene valores' })
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => ValorDto)
  valores: ValorDto[];

  @ApiPropertyOptional({ example: 'Muestra tomada en el tanque de almacenamiento' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  observacion?: string;
}

export class CambiarEstadoDto {
  @ApiProperty({ enum: ESTADOS })
  @IsIn(ESTADOS, { message: `El estado debe ser uno de: ${ESTADOS.join(', ')}` })
  estado: Estado;
}
