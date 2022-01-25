class Document < ApplicationRecord
  # TODO: add price regex for $5. This only finds 5.00
  PRICE_REGEX = /\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})/

  # fill document model from text input
  def fill_from_upload(text)
    text_by_line = text.downcase.split("\n")
    text_by_line.each_with_index do |line, index|
      # print out in development to help debug
      if Rails.env == "development"
        puts line
      end
      # check each line for one thing. might want to change this to look for everything in each line
      next if fill_tax(line, index, text_by_line)
      next if fill_amount_due(line, index, text_by_line)
      next if fill_amount(line, index, text_by_line)
      next if fill_date(line)
    end
  end

  # fill tax given text
  def fill_tax(current_text, index, all_text_by_line)
    if current_text.match(/tax/) || current_text.match(/gst/) || current_text.match(/hst/)
      tax_amount = look_for_price(current_text, index, all_text_by_line)
      if tax_amount.present?
        self.tax = tax_amount
        return true
      end
    end
    return false
  end

   # fill amount given text
  def fill_amount(current_text, index, all_text_by_line)
    # need to guard against subtotal vs total when finding full amount. this is why
    # the text is wrapped in spaces to ensure the word total is found even
    # when at the start of the text
    if current_text.match(/amount/) || " #{current_text} ".match(/\s+total/)
      total_amount = look_for_price(current_text, index, all_text_by_line)
      if total_amount.present?
        self.amount = total_amount
        return true
      end
    end
    return false
  end

   # fill amount due given text
  def fill_amount_due(current_text, index, all_text_by_line)
    if current_text.match(/due/)
      amount_due = look_for_price(current_text, index, all_text_by_line)
      if amount_due.present?
        self.amount_due = amount_due
        return true
      end
    end
    return false
  end

  # search for price given a line of text. if the price can't be found in the
  # current line of text, check the following line and preceding line for a price.
  # this also checks for currency of price
  def look_for_price(current_text, index, all_text_by_line)
    # check for price in current line first
    price = current_text.match(PRICE_REGEX)

    # check for price in following line
    if !price.present? && all_text_by_line[index+1].present?
      price = all_text_by_line[index+1].match(PRICE_REGEX)
    end

    # check for price in preceding line
    if !price.present? && all_text_by_line[index-1].present?
      price = all_text_by_line[index-1].match(PRICE_REGEX)
    end

    # look for currency if price is found
    if price.present?
      currency = look_for_currency(current_text) || look_for_currency(all_text_by_line[index+1]) ||
          look_for_currency(all_text_by_line[index-1])
      if currency.present?
        self.currency = currency
      end
    end

    return price
  end

  # check text for currency string
  def look_for_currency(text)
    if text.present?
      # TODO: get full list of currencies and save them in file under lib directory
      currencies = ["usd", "cad", "gbp"]
      currencies.each do |currency|
        if text.include?(currency)
          return currency
        end
      end
    end
    return nil
  end

  # fill date from text
  def fill_date(text)
    # multiple regex for different date formats
    date_match = text.match(/[a-z.]+[ ]+[0-9]+[, ]+[0-9]+/) ||
        text.match(/[0-9]+[, ]+[a-z.]+[ ]+[0-9]+/) ||
        text.match(/[0-9]+[\-\/]+[0-9]+[\-\/]+[0-9]+/)
    if date_match.present?
      date = DateTime.parse(date_match[0])
      # assumption: oldest date on receipt should be date of invoice
      if self.invoice_date.present? && self.invoice_date < date
        return true
      end
      self.invoice_date = date
      return true
    end
    return false
  end
end