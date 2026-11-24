import { MigrationInterface, QueryRunner } from "typeorm";

export class Inicial1795537881113 implements MigrationInterface {
    name = 'Inicial1795537881113'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."usuarios_rol_enum" AS ENUM('operario', 'administrador', 'consultor_siga')`);
        await queryRunner.query(`CREATE TABLE "usuarios" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "nombre" character varying(100) NOT NULL, "correo" character varying(150) NOT NULL, "clave_hash" character varying(200) NOT NULL, "rol" "public"."usuarios_rol_enum" NOT NULL DEFAULT 'operario', "creado_en" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "UQ_63665765c1a778a770c9bd585d3" UNIQUE ("correo"), CONSTRAINT "PK_d7281c63c176e152e4c531594a8" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "mensajes" ("id" SERIAL NOT NULL, "sesion" character varying(60) NOT NULL, "rol" character varying(10) NOT NULL, "contenido" text NOT NULL, "modelo" character varying(80), "creado_en" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "usuario_id" uuid NOT NULL, CONSTRAINT "PK_20c919d08249bb93d84ce01beb4" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_895b91cbb9a2aec5605824f4fa" ON "mensajes"  ("usuario_id", "sesion", "creado_en") `);
        await queryRunner.query(`CREATE TYPE "public"."parametros_tipo_enum" AS ENUM('fisicoquimico', 'medidores', 'caudal')`);
        await queryRunner.query(`CREATE TABLE "parametros" ("id" character varying(40) NOT NULL, "nombre" character varying(100) NOT NULL, "unidad" character varying(20) NOT NULL, "tipo" "public"."parametros_tipo_enum" NOT NULL, "minimo" numeric(10,3), "maximo" numeric(10,3), "activo" boolean NOT NULL DEFAULT true, CONSTRAINT "PK_c01b42f38ccdc41bdce9cd9fa33" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "planta" ("id" integer NOT NULL, "nombre" character varying(120) NOT NULL, "ubicacion" character varying(120) NOT NULL, "fuente_agua" character varying(120) NOT NULL, "norma_referencia" character varying(160) NOT NULL, CONSTRAINT "PK_799329f262c355b810cd00d461e" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."registros_tipo_enum" AS ENUM('fisicoquimico', 'medidores', 'caudal')`);
        await queryRunner.query(`CREATE TYPE "public"."registros_estado_enum" AS ENUM('pendiente', 'revisado', 'aprobado', 'anulado')`);
        await queryRunner.query(`CREATE TABLE "registros" ("id" SERIAL NOT NULL, "tipo" "public"."registros_tipo_enum" NOT NULL, "origen" character varying(10) NOT NULL, "observacion" character varying(300) NOT NULL DEFAULT '', "fuera_de_rango" boolean NOT NULL DEFAULT false, "estado" "public"."registros_estado_enum" NOT NULL DEFAULT 'pendiente', "creado_en" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "usuario_id" uuid NOT NULL, CONSTRAINT "PK_34c305689a504166a73ccaec0b0" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "registro_valores" ("id" SERIAL NOT NULL, "valor" numeric(12,4) NOT NULL, "minimo_vigente" numeric(10,3), "maximo_vigente" numeric(10,3), "fuera_de_rango" boolean NOT NULL DEFAULT false, "registro_id" integer NOT NULL, "parametro_id" character varying(40) NOT NULL, CONSTRAINT "PK_91d9cbaaaa525195f4e43b2e985" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "mensajes" ADD CONSTRAINT "FK_b54437b6a7023ab7f977279dbc1" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "registros" ADD CONSTRAINT "FK_1f3998933963eacc59aee66638f" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "registro_valores" ADD CONSTRAINT "FK_131a3e6523d2581f761ea6005f0" FOREIGN KEY ("registro_id") REFERENCES "registros"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "registro_valores" ADD CONSTRAINT "FK_d77931e4838700250f5c19a545a" FOREIGN KEY ("parametro_id") REFERENCES "parametros"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "registro_valores" DROP CONSTRAINT "FK_d77931e4838700250f5c19a545a"`);
        await queryRunner.query(`ALTER TABLE "registro_valores" DROP CONSTRAINT "FK_131a3e6523d2581f761ea6005f0"`);
        await queryRunner.query(`ALTER TABLE "registros" DROP CONSTRAINT "FK_1f3998933963eacc59aee66638f"`);
        await queryRunner.query(`ALTER TABLE "mensajes" DROP CONSTRAINT "FK_b54437b6a7023ab7f977279dbc1"`);
        await queryRunner.query(`DROP TABLE "registro_valores"`);
        await queryRunner.query(`DROP TABLE "registros"`);
        await queryRunner.query(`DROP TYPE "public"."registros_estado_enum"`);
        await queryRunner.query(`DROP TYPE "public"."registros_tipo_enum"`);
        await queryRunner.query(`DROP TABLE "planta"`);
        await queryRunner.query(`DROP TABLE "parametros"`);
        await queryRunner.query(`DROP TYPE "public"."parametros_tipo_enum"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_895b91cbb9a2aec5605824f4fa"`);
        await queryRunner.query(`DROP TABLE "mensajes"`);
        await queryRunner.query(`DROP TABLE "usuarios"`);
        await queryRunner.query(`DROP TYPE "public"."usuarios_rol_enum"`);
    }

}
