
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "wrappers" WITH SCHEMA "public";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."courses" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying NOT NULL,
    "description" "text",
    "amount" numeric NOT NULL,
    "currency" character varying DEFAULT 'USD'::character varying NOT NULL
);

ALTER TABLE "public"."courses" OWNER TO "postgres";

ALTER TABLE "public"."courses" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."Course_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."modules" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying NOT NULL,
    "description" "text",
    "course_id" bigint NOT NULL,
    "number" smallint NOT NULL
);

ALTER TABLE "public"."modules" OWNER TO "postgres";

ALTER TABLE "public"."modules" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."Module_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."videos" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "module_id" bigint NOT NULL,
    "number" integer NOT NULL,
    "name" character varying NOT NULL,
    "description" "text",
    "vimeo_url" character varying
);

ALTER TABLE "public"."videos" OWNER TO "postgres";

ALTER TABLE "public"."videos" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."Video_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."orders" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "course_id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "amount" numeric NOT NULL,
    "updated_at" timestamp with time zone,
    "status" character varying NOT NULL,
    "stripe_payment_intent_id" character varying NOT NULL,
    "currency" character varying DEFAULT 'USD'::character varying NOT NULL,
    "ever_disputed" boolean
);

ALTER TABLE "public"."orders" OWNER TO "postgres";

ALTER TABLE "public"."orders" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."orders_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "first_name" "text",
    "last_name" "text"
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "course_id" bigint NOT NULL,
    "start_date" timestamp with time zone NOT NULL,
    "end_date" timestamp with time zone NOT NULL,
    "revoked" boolean,
    "order_id" bigint NOT NULL
);

ALTER TABLE "public"."subscriptions" OWNER TO "postgres";

ALTER TABLE "public"."subscriptions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."subscriptions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY "public"."courses"
    ADD CONSTRAINT "Course_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."modules"
    ADD CONSTRAINT "Module_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "Video_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");

CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');

ALTER TABLE ONLY "public"."modules"
    ADD CONSTRAINT "modules_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id");

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id");

ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id");

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id");

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."videos"
    ADD CONSTRAINT "videos_module_id_fkey" FOREIGN KEY ("module_id") REFERENCES "public"."modules"("id");

CREATE POLICY "Enable read access for all users" ON "public"."courses" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."modules" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."subscriptions" FOR SELECT USING (true);

CREATE POLICY "Profiles are viewable by users who created them." ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));

CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));

CREATE POLICY "Users having subscription can access videos" ON "public"."videos" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."subscriptions" "s"
     JOIN "public"."modules" "m" ON (("m"."course_id" = "s"."course_id")))
  WHERE (("m"."id" = "videos"."module_id") AND ("s"."user_id" = "auth"."uid"()) AND (("s"."end_date" IS NULL) OR ("s"."end_date" > "now"())) AND ("s"."revoked" IS NOT TRUE)))));

ALTER TABLE "public"."courses" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."modules" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."videos" ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."airtable_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."airtable_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."airtable_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."airtable_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."airtable_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."airtable_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."airtable_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."airtable_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."airtable_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."airtable_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."airtable_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."airtable_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON FUNCTION "public"."big_query_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."big_query_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."big_query_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."big_query_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."big_query_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."big_query_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."big_query_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."big_query_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."big_query_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."big_query_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."big_query_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."big_query_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON FUNCTION "public"."click_house_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."click_house_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."click_house_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."click_house_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."click_house_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."click_house_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."click_house_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."click_house_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."click_house_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."click_house_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."click_house_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."click_house_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON FUNCTION "public"."firebase_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."firebase_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."firebase_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."firebase_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."firebase_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."firebase_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."firebase_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."firebase_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."firebase_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."firebase_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."firebase_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."firebase_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

-- trigger the function every time a user is created
-- https://github.com/supabase/cli/issues/120
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

GRANT ALL ON FUNCTION "public"."logflare_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."logflare_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."logflare_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."logflare_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."logflare_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."logflare_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."logflare_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."logflare_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."logflare_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."logflare_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."logflare_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."logflare_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON FUNCTION "public"."s3_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."s3_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."s3_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."s3_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."s3_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."s3_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."s3_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."s3_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."s3_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."s3_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."s3_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."s3_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON FUNCTION "public"."stripe_fdw_handler"() TO "postgres";
GRANT ALL ON FUNCTION "public"."stripe_fdw_handler"() TO "anon";
GRANT ALL ON FUNCTION "public"."stripe_fdw_handler"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."stripe_fdw_handler"() TO "service_role";

GRANT ALL ON FUNCTION "public"."stripe_fdw_meta"() TO "postgres";
GRANT ALL ON FUNCTION "public"."stripe_fdw_meta"() TO "anon";
GRANT ALL ON FUNCTION "public"."stripe_fdw_meta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."stripe_fdw_meta"() TO "service_role";

GRANT ALL ON FUNCTION "public"."stripe_fdw_validator"("options" "text"[], "catalog" "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."stripe_fdw_validator"("options" "text"[], "catalog" "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."stripe_fdw_validator"("options" "text"[], "catalog" "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."stripe_fdw_validator"("options" "text"[], "catalog" "oid") TO "service_role";

GRANT ALL ON TABLE "public"."courses" TO "anon";
GRANT ALL ON TABLE "public"."courses" TO "authenticated";
GRANT ALL ON TABLE "public"."courses" TO "service_role";

GRANT ALL ON SEQUENCE "public"."Course_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."Course_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."Course_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."modules" TO "anon";
GRANT ALL ON TABLE "public"."modules" TO "authenticated";
GRANT ALL ON TABLE "public"."modules" TO "service_role";

GRANT ALL ON SEQUENCE "public"."Module_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."Module_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."Module_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."videos" TO "anon";
GRANT ALL ON TABLE "public"."videos" TO "authenticated";
GRANT ALL ON TABLE "public"."videos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."Video_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."Video_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."Video_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";

GRANT ALL ON SEQUENCE "public"."orders_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."orders_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."orders_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";

GRANT ALL ON SEQUENCE "public"."subscriptions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."subscriptions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."subscriptions_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."wrappers_fdw_stats" TO "postgres";
GRANT ALL ON TABLE "public"."wrappers_fdw_stats" TO "anon";
GRANT ALL ON TABLE "public"."wrappers_fdw_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."wrappers_fdw_stats" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;