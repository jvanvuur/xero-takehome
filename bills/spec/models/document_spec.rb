require 'rails_helper'

RSpec.describe "Document", :type => :model do
  let(:doc) { Document.new }
  # test amount due and amount
  describe "#fill_from_upload" do
    it "should fill document" do
      document_text =
        "the company\n" +
        "December 20, 2021\n" +
        "Total $50.00\n" +
        "Tax $5.00\n" +
        "Amount due\n" +
        "$55.00 CAD\n"
      doc.fill_from_upload(document_text)

      expect(doc.vendor).to eq(nil)
      expect(doc.invoice_date).to eq(DateTime.parse("december 20, 2021"))
      expect(doc.amount).to eq(50)
      expect(doc.amount_due).to eq(55)
      expect(doc.currency).to eq('cad')
      expect(doc.tax).to eq(5)
      expect(doc.status).to eq(nil)
    end
  end

  # default to CAD currency
  describe "#fill_tax" do
    it "should not fill tax field when no tax info is found" do
      doc.fill_tax("amount: $2.00", 0, [])
      expect(doc.tax).to eq(nil)
    end
    it "should fill tax field when tax is found" do
      doc.fill_tax("tax: $2.00", 0, [])
      expect(doc.tax).to eq(2)
    end
    it "should fill tax field when gst is found" do
      doc.fill_tax("gst: $2.00", 0, [])
      expect(doc.tax).to eq(2)
    end
    it "should fill tax field when hst is found" do
      doc.fill_tax("hst: $2.00", 0, [])
      expect(doc.tax).to eq(2)
    end
  end

  describe "#fill_amount" do
    it "should not fill amount field when no amount info is found" do
      doc.fill_amount("tax: $2.00", 0, [])
      expect(doc.amount).to eq(nil)
    end
    it "should fill amount field when amount is found" do
      doc.fill_amount("amount: $2.00", 0, [])
      expect(doc.amount).to eq(2)
    end
    it "should fill amount field when total is found" do
      doc.fill_amount("total: $2.00", 0, [])
      expect(doc.amount).to eq(2)
    end
    it "should not fill amount field when subtotal is found" do
      doc.fill_amount("subtotal: $2.00", 0, [])
      expect(doc.amount).to eq(nil)
    end
  end

  describe "#fill_amount_due" do
    it "should not fill amount_due field when no amount info is found" do
      doc.fill_amount_due("tax: $2.00", 0, [])
      expect(doc.amount_due).to eq(nil)
    end
    it "should fill amount_due field when amount is found" do
      doc.fill_amount_due("amount due: $2.00", 0, [])
      expect(doc.amount_due).to eq(2)
    end
    it "should fill amount_due field when due is found" do
      doc.fill_amount_due("due: $2.00", 0, [])
      expect(doc.amount_due).to eq(2)
    end
  end

  describe "#look_for_price" do
    it "should find price on current line" do
      price = doc.look_for_price("amount due    $3.00", 0, [])
      expect(price[0]).to eq('3.00')
    end
    it "should find price on following line if not found on current line" do
      price = doc.look_for_price("amount due", 1, ["final bill", "amount due", "$40.00"])
      expect(price[0]).to eq('40.00')
    end
    it "should find price on preceding line if not found on current line" do
      price = doc.look_for_price("amount due", 1, ["$50.00", "amount due", "usd"])
      expect(price[0]).to eq('50.00')
    end
    it "should find price on following first and not on preceding line" do
      price = doc.look_for_price("amount due", 1, ["$50.00", "amount due", "$40.00"])
      expect(price[0]).to eq('40.00')
    end
    it "should not fail on array index being out of range" do
      price = doc.look_for_price("amount due", 0, ["amount due"])
      expect(price).to eq(nil)
    end
    it "should fill currency if it finds a currency string near a price" do
      price = doc.look_for_price("amount due", 1, ["$50.00", "amount due", "usd"])
      expect(doc.currency).to eq('usd')
    end
  end

  describe "#look_for_currency" do
    it "should find currency" do
      currency = doc.look_for_currency("3.00 usd")
      expect(currency).to eq('usd')

      currency = doc.look_for_currency("usd")
      expect(currency).to eq('usd')

      currency = doc.look_for_currency("3.00 cad")
      expect(currency).to eq('cad')
    end
  end

  describe "#fill_date" do
    it "should find dates of format Dec 12, 2012" do
      doc.fill_date("march 12, 2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("mar. 12, 2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("mar 12, 2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("mar 12 2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)
    end

    it "should find dates of format 2021 Dec 12" do
      doc.fill_date("2021, march 12")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("2021 mar. 12")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("2021 mar 12")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("2021 mar 12")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)
    end

    it "should find dates of format 2012/09/09" do
      doc.fill_date("12/03/2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("12-03-2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("12 03 2021")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)

      doc.fill_date("2021 12 03")
      expect(doc.invoice_date.day).to eq(12)
      expect(doc.invoice_date.month).to eq(3)
      expect(doc.invoice_date.year).to eq(2021)
    end

    it "should overwrite date if there is an older date in the input string" do
      doc.invoice_date = DateTime.parse('march 20, 2021')
      doc.fill_date('march 18, 2021')

      expect(doc.invoice_date.day).to eq(18)
    end

    it "should not overwrite date if there is an newer date in the input string" do
      doc.invoice_date = DateTime.parse('march 20, 2021')
      doc.fill_date('March 22, 2021')

      expect(doc.invoice_date.day).to eq(20)
    end
  end
end