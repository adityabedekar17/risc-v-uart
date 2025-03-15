TARGET := ltuffy_abedekar_cse293_report.pdf

all: build/$(TARGET)
build/$(TARGET): final_report.md
	@mkdir -p build
	pandoc -f markdown -t pdf $^ -o $@

clean:
	rm -rf build
