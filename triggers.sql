CREATE OR REPLACE FUNCTION check_inventory() RETURNS TRIGGER AS $check_inventory$
    DECLARE
			counter integer := 0;
	BEGIN
		IF (TG_OP = 'UPDATE') THEN
			IF OLD.status = 'placed' and new.status = 'completed' and old.model_id = new.model_id and new.qty = old.qty THEN
			 RETURN NEW;
			ELSIF old.model_id <> new.model_id OR new.qty <> old.qty THEN
				select i.count into counter from inventory i where i.model_id = NEW.model_id;
			 		IF new.qty > counter THEN
            			RAISE EXCEPTION '% dont have enough quantity in inventory for model', NEW.model_id;
       				 END IF;
			END IF;
		ELSIF (TG_OP = 'INSERT') THEN
        	IF NEW.model_id > 0 and NEW.qty > 0 THEN
            	select i.count into counter from inventory i where i.model_id = NEW.model_id;
			 		IF new.qty > counter THEN
            			RAISE EXCEPTION '% dont have enough quantity in inventory for model', NEW.model_id;
       				 END IF;
			END IF;		 
        END IF;
        RETURN NEW;
    END;
	$check_inventory$ LANGUAGE plpgsql;
	
	
	CREATE TRIGGER check_inventory BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW EXECUTE PROCEDURE check_inventory();
	
	
	
	CREATE OR REPLACE FUNCTION update_inventory() RETURNS TRIGGER AS $update_inventory$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
--             update inventory set count = count + OLD.qty where model_id = OLD.model_id;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
			if(Old.status <> new.status and new.status = 'cancelled') THEN 
				update inventory set count = count + OLD.qty where model_id = OLD.model_id;
			elsif(new.model_id <> old.model_id and new.status <> 'cancelled') THEn
				update inventory set count = count + OLD.qty where model_id = OLD.model_id;
				update inventory set count = count - NEW.qty where model_id = NEW.model_id;
			elsif(new.qty <> old.qty and new.status <> 'cancelled') THEn
				update inventory set count = count + old.qty - NEW.qty where model_id = NEW.model_id;
			elsif(Old.status = 'cancelled' and new.status <> 'cancelled') THEN 
				update inventory set count = count - NEW.qty where model_id = NEW.model_id;
			END IF;	
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
          update inventory set count = count - NEW.qty where model_id = NEW.model_id;
            RETURN NEW;
        END IF;
        RETURN NULL; 
    END;
$update_inventory$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory
AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW EXECUTE PROCEDURE update_inventory();
	
	

	