for file in *.sh; do
  echo "Filename: $file" >> combined_file.sh
  cat "$file" >> combined_file.sh
  echo -e "\n" >> combined_file.sh
done
