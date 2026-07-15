TABLES := ssdt-bix

.PHONY: all clean

all: $(TABLES:%=aml/%.aml)

aml/%.aml: dsl/%.dsl
	mkdir -p aml hex
	iasl -tc -p aml/$* $<
	mv aml/$*.hex hex/$*.hex

clean:
	rm -f aml/*.aml hex/*.hex
