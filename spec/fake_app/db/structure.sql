CREATE TABLE cities (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
);

CREATE TABLE managers (
    id integer NOT NULL,
    email character varying,
    password_digest character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


CREATE TABLE offices (
    id integer NOT NULL,
    name character varying,
    address character varying,
    phone character varying,
    description text,
    capacity integer,
    manager_id integer,
    city_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
