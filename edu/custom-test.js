const response1 = await insomnia.send();
expect(response1.status).to.equal(201);
const body = JSON.parse(response1.data);
expect(body).to.have.all.keys('ticket_number');